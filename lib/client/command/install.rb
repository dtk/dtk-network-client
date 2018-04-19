module DTK::Network::Client
  class Command
    class Install < self
      include DTK::Network::Client::Util::Tar
      include DTK::Network::Client::Util::OsUtil

      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @explicit_path    = module_ref.explicit_path
        @options          = options
        @parsed_module    = options[:parsed_module]
        @ret              = []
        @type             = options[:type]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.get_or_create(module_ref, opts.merge(format: :hash))
        new(module_ref, dependency_tree, opts).install
      end

      def install
        FileUtils.mkdir_p(dtk_modules_gzip_location) unless Dir.exist?(dtk_modules_gzip_location)

        module_list = @dependency_tree.dup
        module_list << { namespace: @module_ref.namespace, name:@module_ref.name, version: @module_ref.version.str_version }

        modules_info = rest_get('modules/install', { module_list: module_list.to_json })
        main_module  = ret_main_module_install_info(modules_info)

        (modules_info || []).each do |module_info|
          dep_module_list = module_info['module_list']
          # credentials = module_info.dig('credentails', 'credentials')
          credentials = (module_info['credentails']||{})['credentials']

          raise Error.new('Unexpected that repoman did not return any credentials') unless credentials

          s3_args = Args.new({
            region:           'us-east-1',
            access_key_id:     credentials['access_key_id'],
            secret_access_key: credentials['secret_access_key'],
            session_token:     credentials['session_token']
          })
          storage = Storage.new(:s3, s3_args)

          dep_module_list.each do |module_info|
            if ModuleRef::Version.is_semantic_version?(module_info['version'])
              install_semantic_version(module_info, storage)
            else
              install_named_version(module_info)
            end
          end
        end

        install_main_module(main_module)
        @ret
      end

      def install_main_module(module_info)
        credentials = module_info['credentials']
        s3_args = Args.new({
          region:           'us-east-1',
          access_key_id:     credentials['access_key_id'],
          secret_access_key: credentials['secret_access_key'],
          session_token:     credentials['session_token']
        })
        storage = Storage.new(:s3, s3_args)

        namespace, name = module_info['name'].split('/')
        module_location = nil

        unless @type == :dependency
          module_location = @explicit_path || "#{@module_directory}/#{name}"
        end

        if ModuleRef::Version.is_semantic_version?(module_info['version'])
          module_location = install_semantic_version(module_info, storage, module_location)
        else
          module_location = install_named_version(module_info, module_location)
        end

        ModuleDir.create_file_with_content("#{module_location}/#{DependencyTree::LOCK_FILE}", YAML.dump(convert_to_module_ref_lock_format(@dependency_tree)))
        # print "Main module installed in '#{module_location}'.\n"
      end

      def ret_main_module_install_info(modules_info = [])
        main_module_info = nil

        modules_info.each do |module_info|
          break if main_module_info

          module_list      = module_info['module_list'] || []
          main_module_info = module_list.find { |mod_info| mod_info['name'].eql?("#{@module_ref.namespace}/#{@module_ref.name}") && mod_info['version'].eql?(@module_ref.version.str_version) }

          if main_module_info
            module_list.delete(main_module_info)
            # credentials = module_info.dig('credentails', 'credentials')
            credentials = (module_info['credentails']||{})['credentials']
            main_module_info.merge!('credentials' => credentials)
          end
        end

        main_module_info
      end

      def install_semantic_version(module_info, storage, target_location = nil)
        bucket, object_name = ret_s3_bucket_info(module_info)
        object_name_on_disk = object_name.gsub(/([\/])/,'__')
        object_location_on_disk = "#{dtk_modules_gzip_location}/#{object_name_on_disk}"
        download_args = Args.new({
          response_target: object_location_on_disk,
          bucket: bucket,
          key: object_name,
          response_content_encoding: "gzip"
        })
        storage.download(download_args)
        install_location = target_location || "#{dtk_modules_location}/#{module_info['name']}-#{module_info['version']}"

        FileUtils.rm_rf(install_location) if Dir.exist?(install_location)

        FileUtils.mkdir_p(install_location)
        `tar xC #{install_location} -f #{object_location_on_disk}`
        # ModuleDir.ungzip_and_untar(object_location_on_disk, install_location)
        FileUtils.remove_entry(object_location_on_disk)

        @ret << module_info.merge(location: install_location)
        print "Module installed in '#{install_location}'.\n"
        install_location
      end

      def install_named_version(module_info, target_location = nil)
        codecommit_uri   = construct_clone_url(module_info['codecommit_uri'])#module_info['codecommit_uri']
        install_location = target_location || "#{dtk_modules_location}/#{module_info['name']}-#{module_info['version']}"

        FileUtils.rm_rf(install_location) if Dir.exist?(install_location)

        GitClient.clone(codecommit_uri, install_location, module_info['version'])

        @ret << module_info.merge(location: install_location)
        print "Module installed in '#{install_location}'.\n"
        install_location
      end

      def ret_s3_bucket_info(module_info)
        bucket = nil
        object_name = nil

        # if meta = module_info['meta']
        if catalog_uri = module_info['uri']
          if match = catalog_uri.match(/.*amazonaws.com\/([^\/]*)\/(.*.gz)/)
            bucket = match[1]
            object_name = match[2]
          end
        else
          raise "Unexpected that publish response does not contain metadata!"
        end

        raise "Unable to extract bucket and/or object name data from catalog_uri!" if bucket.nil? || object_name.nil?

        return [bucket, object_name]
      end

      def construct_clone_url(codecommit_uri)
        require 'open-uri'

        if codecommit_uri # = module_info.dig('meta', 'aws', 'codecommit', 'repository_metadata', 'codecommit_uri')
          codecommit_data   = Session.get_codecommit_data
          # service_user_name = codecommit_data.dig('service_specific_credential', 'service_user_name')
          service_user_name = codecommit_data['service_specific_credential']['service_user_name']
          # service_password  = codecommit_data.dig('service_specific_credential', 'service_password')
          service_password  = codecommit_data['service_specific_credential']['service_password']
          encoded_password  = URI.encode_www_form_component(service_password)
          url = nil
          if match = codecommit_uri.match(/^(https:\/\/)(.*)$/)
            url = "#{match[1]}#{service_user_name}:#{encoded_password}@#{match[2]}"
          end
          url
        else
          raise "Unable to find codecommit https url"
        end
      end

      def convert_to_module_ref_lock_format(dep_tree)
        lock_format = {}

        dep_tree.each do |dep|
          dep_name = "#{dep[:namespace]}/#{dep[:name]}"

          full_dep = { dep_name => {} }

          if version = (dep[:version] || dep['version'])
            full_dep[dep_name].merge!({ 'version' => version })
          end

          if modules = (dep[:modules] || dep['modules'])
            full_dep[dep_name].merge!({ 'modules' => modules })
          end

          lock_format.merge!(full_dep)
        end

        lock_format
        # dep_tree.inject({}) { |h, dep| h.merge!({ "#{dep[:namespace]}/#{dep[:name]}" => { 'version' => (dep[:version] || dep['version']), 'modules' => (dep[:modules] || dep['modules']) }})}
      end
    end
  end
end

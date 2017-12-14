module DTK::Network::Client
  class Command
    class Install < self
      include DTK::Network::Client::Util::Tar
      include DTK::Network::Client::Util::OsUtil

      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.get_dependency_tree(module_ref, opts.merge(format: :hash))
        new(module_ref, dependency_tree, opts).install
      end

      def install
        FileUtils.mkdir_p(dtk_modules_gzip_location) unless Dir.exist?(dtk_modules_gzip_location)

        module_list = @dependency_tree
        module_list << { namespace: @module_ref.namespace, name:@module_ref.name, version: @module_ref.version.str_version }

        modules_info = rest_get('modules/install', { module_list: module_list.to_json })
        main_module  = ret_main_module_install_info(modules_info)

        (modules_info || []).each do |module_info|
          dep_module_list = module_info['module_list']
          credentials = module_info.dig('credentails', 'credentials')

          raise Error.new('Unexpected that repoman did not return any credentials') unless credentials

          s3_args = Args.new({
            region:           'us-east-1',
            access_key_id:     credentials['access_key_id'],
            secret_access_key: credentials['secret_access_key'],
            session_token:     credentials['session_token']
          })
          storage = Storage.new(:s3, s3_args)

          dep_module_list.each do |module_info|
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
            install_location = "#{dtk_modules_location}/#{module_info['name']}-#{module_info['version']}"

            ModuleDir.ungzip_and_untar(object_location_on_disk, install_location)
            FileUtils.remove_entry(object_location_on_disk)

            print "Module installed in '#{install_location}'.\n"
          end
        end

        install_main_module(main_module)
      end

      def install_main_module(main_module)
        credentials = main_module['credentials']
        s3_args = Args.new({
          region:           'us-east-1',
          access_key_id:     credentials['access_key_id'],
          secret_access_key: credentials['secret_access_key'],
          session_token:     credentials['session_token']
        })
        storage = Storage.new(:s3, s3_args)

        bucket, object_name = ret_s3_bucket_info(main_module)
        object_name_on_disk = object_name.gsub(/([\/])/,'__')
        object_location_on_disk = "#{dtk_modules_gzip_location}/#{object_name_on_disk}"
        download_args = Args.new({
          response_target: object_location_on_disk,
          bucket: bucket,
          key: object_name,
          response_content_encoding: "gzip"
        })
        storage.download(download_args)
        install_location = @module_directory#"#{dtk_modules_location}/#{main_module['name']}-#{main_module['version']}"

        ModuleDir.ungzip_and_untar(object_location_on_disk, install_location)
        FileUtils.remove_entry(object_location_on_disk)

        print "Main module installed in '#{install_location}'.\n"
      end

      def ret_main_module_install_info(modules_info = [])
        main_module_info = nil

        modules_info.each do |module_info|
          break if main_module_info

          module_list      = module_info['module_list'] || []
          main_module_info = module_list.find { |mod_info| mod_info['name'].eql?("#{@module_ref.namespace}/#{@module_ref.name}") && mod_info['version'].eql?(@module_ref.version.str_version) }

          if main_module_info
            module_list.delete(main_module_info)
            credentials = module_info.dig('credentails', 'credentials')
            main_module_info.merge!('credentials' => credentials)
          end
        end

        main_module_info
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
    end
  end
end

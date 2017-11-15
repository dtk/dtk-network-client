module DTK::Network::Client
  class Command
    class Publish < self
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.compute_and_save(module_ref, opts)
        new(module_ref, dependency_tree, opts).publish
      end

      def publish
        c_module = rest_post('modules/create_by_name', { name: @module_ref.name, namespace: @module_ref.namespace })

        module_id    = c_module['id']
        dependencies = []

        if @parsed_module
          (@parsed_module.val(:DependentModules) || []).map do |parsed_mr|
            dependencies << { 'namespace' => parsed_mr.req(:Namespace), 'module' => parsed_mr.req(:ModuleName), 'version' => parsed_mr.val(:ModuleVersion) }
          end
        end

        branch = rest_post("modules/#{module_id}/branch", { version: @module_ref.version, dependencies: dependencies.to_json })

        published = rest_post("modules/#{module_id}/publish", { version: @module_ref.version })
        published

        gzip_name = create_tar_gz(published)

        upload_file_location = "#{@module_directory}/#{gzip_name}"
        published_creds = published['publish_credentails']

        require 'aws-sdk'
        bucket = 'dtkn-dev-catalog'
        file_key = gzip_name.gsub('__','/')
        s3 = Aws::S3::Client.new(
          region: 'us-east-1',
          access_key_id: published_creds['access_key_id'],
          secret_access_key: published_creds['secret_access_key'],
          session_token: published_creds['session_token']
        )
        resp = s3.put_object({
          body: upload_file_location,
          bucket: bucket,
          key: file_key
        })
        resp
      end

      def create_tar_gz(published)
        s3_locaction = 'https://s3.amazonaws.com/dtkn-dev-catalog/'

        if branch = published['branch']
          meta        = branch['meta']
          catalog_uri = meta['catalog_uri']
          gzip_name   = nil
          
          if match = catalog_uri.match(/(#{s3_locaction})(.*)/)
            gzip_name = match[2]
          end

          if gzip_name
            # `tar -czf #{gzip_name} #{file_name}`
            `tar czf #{gzip_name.gsub!('/','__')} .`
            gzip_name
          end
        end
      end

      # def create_tar_gz(published)
      #   require 'rubygems/package'
      #   s3_locaction = 'https://s3.amazonaws.com/dtkn-dev-catalog/'

      #   if branch = published['branch']
      #     meta = branch['meta']
      #     catalog_uri = meta['catalog_uri']
      #     gzip_name = nil
          
      #     if match = catalog_uri.match(/(#{s3_locaction})(.)/)
      #       gzip_name = match[2]
      #     end

      #     if gzip_name
      #       File.open("#{gzip_name}", "wb") do |file|
      #         Zlib::GzipWriter.wrap(file) do |gz|
      #           Gem::Package::TarWriter.new(gz) do |tar|
      #             awesome_stuff = "This is awesome!\n"
      #             tar.add_file_simple("awesome/stuff.txt",
      #               0444, awesome_stuff.length
      #             ) do |io|
      #               io.write(awesome_stuff)
      #             end
            
      #             more_awesome = "This is awesome, too!\n"
      #             tar.add_file_simple("more/awesome.txt",
      #               0444, more_awesome.length
      #             ) do |io|
      #               io.write(more_awesome)
      #             end
      #           end
      #         end
      #       end
      #     end
      #   end

      # end
    end
  end
end
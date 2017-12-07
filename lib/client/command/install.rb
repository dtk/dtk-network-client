module DTK::Network::Client
  class Command
    class Install < self
      include DTK::Network::Client::Util::Tar

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
        module_list = @dependency_tree
        module_list << { namespace: @module_ref.namespace, name:@module_ref.name, version: @module_ref.version }

        modules_info = rest_get('modules/install', { module_list: module_list.to_json })

        (modules_info || []).each do |dependency_modules|
          module_list = dependency_modules['module_list']
          credentials = dependency_modules.dig('credentails', 'credentials')

          raise Error.new('Unexpected that repoman did not return any credentials') unless credentials

          s3_args = Args.new({
            region: 'us-east-1',
            access_key_id: credentials['access_key_id'],
            secret_access_key: credentials['secret_access_key'],
            session_token: credentials['session_token']
          })
          storage = Storage.new(:s3, s3_args)

          module_list.each do |module_info|
            bucket, object_name = ret_s3_bucket_info(module_info)
            object_name_on_disk = object_name.gsub(/([\/])/,'__')
            object_location_on_disk = "/home/ubuntu/dtk/modules/download_location/#{object_name_on_disk}"
            download_args = Args.new({
              response_target: object_location_on_disk,
              bucket: bucket,
              key: object_name,
              response_content_encoding: "gzip"
            })

            resp = storage.download(download_args)
            ModuleDir.ungzip_and_untar(object_location_on_disk, "/home/ubuntu/dtk/modules/download_location/")
          end
        end
      end

      def ret_s3_bucket_info(module_info)
        bucket = nil
        object_name = nil

        if meta = module_info['meta']
          catalog_uri = meta['catalog_uri']
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

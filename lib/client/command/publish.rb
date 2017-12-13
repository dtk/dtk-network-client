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
        dependency_tree = DependencyTree.get_dependency_tree(module_ref, opts)
        new(module_ref, dependency_tree, opts).publish
      end

      def publish
        module_info  = rest_post('modules', { name: @module_ref.name, namespace: @module_ref.namespace, return_if_exists: true })
        module_id    = module_info['id']
        dependencies = []

        if @parsed_module
          (@parsed_module.val(:DependentModules) || []).map do |parsed_mr|
            dependencies << { 'namespace' => parsed_mr.req(:Namespace), 'module' => parsed_mr.req(:ModuleName), 'version' => parsed_mr.val(:ModuleVersion) }
          end
        end

        branch   = rest_post("modules/#{module_id}/branch", { version: @module_ref.version, dependencies: dependencies.to_json })
        repo_url = ret_codecommit_url(module_info)

        git_args = Args.new({
          repo_dir: @module_directory,
          branch: branch['name'],
          remote_url: repo_url
        })
        GitRepo.init_and_publish_to_remote(git_args)

        published_response  = rest_post("modules/#{module_id}/publish", { version: @module_ref.version })
        bucket, object_name = ret_s3_bucket_info(published_response)
        gz_body             = ModuleDir.create_and_ret_tar_gz(@module_directory, exclude_git: true)
        published_creds     = published_response['publish_credentails']

        s3_args = Args.new({
          region: 'us-east-1',
          access_key_id: published_creds['access_key_id'],
          secret_access_key: published_creds['secret_access_key'],
          session_token: published_creds['session_token']
        })
        storage = Storage.new(:s3, s3_args)

        upload_args = Args.new({
          body: gz_body,
          bucket: bucket,
          key: object_name
        })
        storage.upload(upload_args)

        branch_id = branch['id']
        rest_post("modules/update_status", { branch_id: branch_id, status: 'published' })
      end

      def ret_s3_bucket_info(published)
        branch = published['branch'] || {}
        bucket = nil
        object_name = nil

        if meta = branch['meta']
          catalog_uri = meta['catalog_uri']
          if match = catalog_uri.match(/.*amazonaws.com\/([^\/]*)\/(.*.gz)/)
            bucket = match[1]
            object_name = match[2]
          end
        else
          raise "Unexpected that publish response does not contain branch metadata!"
        end

        raise "Unable to extract bucket and/or object name data from catalog_uri!" if bucket.nil? || object_name.nil?

        return [bucket, object_name]
      end

      def ret_codecommit_url(module_info)
        require 'open-uri'

        if clone_url_http = module_info.dig('meta', 'aws', 'codecommit', 'repository_metadata', 'clone_url_http')
          codecommit_data = Session.get_codecommit_data
          service_user_name = codecommit_data.dig('service_specific_credential', 'service_user_name')
          service_password = codecommit_data.dig('service_specific_credential', 'service_password')
          encoded_password = URI.encode_www_form_component(service_password)
          url = nil
          if match = clone_url_http.match(/^(https:\/\/)(.*)$/)
            url = "#{match[1]}#{service_user_name}:#{encoded_password}@#{match[2]}"
          end
          url
        else
          raise "Unable to find codecommit https url"
        end
      end

    end
  end
end
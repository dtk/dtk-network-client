module DTK::Network::Client
  class Command
    class Publish < self
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
        @development_mode = options[:development_mode]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.get_or_create(module_ref, opts.merge(save_to_file: true, development_mode: opts[:development_mode]))
        new(module_ref, dependency_tree, opts).publish
      end

      def publish
        module_info  = rest_post('modules', { name: @module_ref.name, namespace: @module_ref.namespace, return_if_exists: true, version: @module_ref.version.str_version })
        dependencies = []

        if @parsed_module
          (@parsed_module.val(:DependentModules) || []).map do |parsed_mr|
            dependencies << { 'namespace' => parsed_mr.req(:Namespace), 'module' => parsed_mr.req(:ModuleName), 'version' => parsed_mr.val(:ModuleVersion) }
          end
        end

        if @development_mode
          puts "Base module.yaml dependencies:\n#{dependencies}"
        end

        if @module_ref.version.is_semantic_version?
          publish_semantic_version(module_info, dependencies)
        else
          publish_named_version(module_info, dependencies)
        end
      end

      def publish_semantic_version(module_info, dependencies)
        module_id          = module_info['id']
        module_ref_version = @module_ref.version
        branch             = rest_post("modules/#{module_id}/branch", { version: module_ref_version.str_version, dependencies: dependencies.to_json })
        # repo_url           = ret_codecommit_url(module_info)

        # git_init_and_publish_to_remote(branch['name'], repo_url)

        published_response  = rest_post("modules/#{module_id}/publish", { version: module_ref_version.str_version })
        bucket, object_name = S3Helper.ret_s3_bucket_info(published_response)
        # gz_body             = ModuleDir.create_and_ret_tar_gz(@module_directory, exclude_git: true)

        resource_name   = object_name.gsub('/','__')
        published_creds = published_response['publish_credentails']
        `tar -cpzf /tmp/#{resource_name} -C #{@module_directory} .`

        require 'aws-sdk-s3'
        s3_args = Args.new({
          region: 'us-east-1',
          access_key_id: published_creds['access_key_id'],
          secret_access_key: published_creds['secret_access_key'],
          session_token: published_creds['session_token']
        })
        s3 = Aws::S3::Resource.new(s3_args)
        # storage = Storage.new(:s3, s3_args)

        obj = s3.bucket(bucket).object(object_name)
        obj.upload_file("/tmp/#{resource_name}")
        FileUtils.remove_entry("/tmp/#{resource_name}")
        # upload_args = Args.new({
          # body: gz_body,
          # bucket: bucket,
          # key: object_name
        # })
        # storage.upload(upload_args)

        rest_post("modules/update_status", { branch_id: branch['id'], status: 'published' })
      end

      def publish_named_version(module_info, dependencies)
        module_id = module_info['id']
        branch    = rest_post("modules/#{module_id}/branch", { version: @module_ref.version.str_version, dependencies: dependencies.to_json })
        repo_url  = ret_codecommit_url(module_info)

        git_init_and_publish_to_remote(branch['name'], repo_url)

        rest_post("modules/update_status", { branch_id: branch['id'], status: 'published' })
      end

      def git_init_and_publish_to_remote(branch, repo_url)
        git_args = Args.new({
          repo_dir:   @module_directory,
          branch:     branch,
          remote_url: repo_url
        })
        GitRepo.add_remote_and_publish(git_args)
      end

      def ret_codecommit_url(module_info)
        require 'open-uri'

        if clone_url_http   = module_info['meta']['aws']['codecommit']['repository_metadata']['clone_url_http']
          codecommit_data   = Session.get_codecommit_data
          service_user_name = codecommit_data['service_specific_credential']['service_user_name']
          service_password  = codecommit_data['service_specific_credential']['service_password']
          encoded_password  = URI.encode_www_form_component(service_password)

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
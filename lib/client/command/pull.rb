module DTK::Network::Client
  class Command
    class Pull < self
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.get_or_create(module_ref, opts.merge(save_to_file: true))
        new(module_ref, dependency_tree, opts).pull
      end

      def pull
        module_info = rest_get('modules/module_info', { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version.str_version })
        remote_url = construct_remote_url(module_info)
        git_args = Args.new({
          repo_dir:   @module_directory,
          branch:     @module_ref.version.str_version,
          remote_url: remote_url
        })
        GitRepo.pull_from_remote(git_args)
      end

      # TODO: move construct_remote_url to helper or mixin and use for all commands when needed
      def construct_remote_url(module_info)
        require 'open-uri'

        if clone_url_http = module_info['meta']['aws']['codecommit']['repository_metadata']['clone_url_http']
          public_user_meta  = module_info['public_user_meta']
          codecommit_data   = public_user_meta || Session.get_codecommit_data
          # codecommit_data   = Session.get_codecommit_data
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
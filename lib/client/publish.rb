module DTK::Network
  module Client
    class Publish
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.compute_and_save(module_ref, opts)
        new(module_ref, dependency_tree, opts).publish
      end

      def publish
        dtkn_module        = Session.rest_post('modules/create', { name: @module_ref.name, namespace: @module_ref.namespace })
        dtkn_module_branch = Session.rest_post('modules/create_branch', { id: dtkn_module['id'], version: @module_ref.version, 
          dependencies: [
            {"namespace"=>"modwork","module"=>"concat","version"=>"~> 0.1.0"},
            {"namespace"=>"modwork","module"=>"puppet","version"=>"<= 0.1.3"}
          ].to_json
        })
        published_dtkn_module = Session.rest_post('modules/publish', { id: dtkn_module['id'], version: @module_ref.version })
      end
    end
  end
end
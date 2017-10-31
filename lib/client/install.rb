module DTK::Network
  module Client
    class Install
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.compute_and_save(module_ref, opts)
        new(module_ref, dependency_tree, opts).install
      end

      def install
        # {"namespace"=>"modwork","module"=>"ec2","version"=>"~> 0.1.0"}
        # {"namespace"=>"modwork","module"=>"apt","version"=>"<= 0.1.3"}
        # {"namespace"=>"modwork","module"=>"mysql","version"=>"0.4.2"}
        # {"namespace"=>"modwork","module"=>"rds","version"=>"~> 0.0.5"}

        # concat: master
        # puppet/nginx: master
        # ec2-0.1.9
        # apt-0.1.3
        # mysql-0.4.2
        # rds-0.0.9



        # dtkn_deps_of_deps = Session.rest_get("modules/dependencies_for_name", { name: "modwork/rds", version: '0.0.9' })
        # Session.rest_post("/modules/dependencies_for_name", { 'name' => "modwork/rds", 'version' => '0.0.9',
        # 'dependencies' => [
          # {"namespace"=>"modwork","module"=>"concat","version"=>"~> 0.1.0"},
          # {"namespace"=>"modwork","module"=>"puppet","version"=>"<= 0.1.3"}
        # ].to_json})
      end
    end
  end
end
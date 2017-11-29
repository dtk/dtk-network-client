module DTK::Network::Client
  class Command
    class Install < self
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        dependency_tree = DependencyTree.compute_and_save_to_file(module_ref, opts)
        new(module_ref, dependency_tree, opts).install
      end

      def install
        @dependency_tree.each do |dep_mod|
          # check if exist on server
          # if true - ask for pull-dtkn
          # else
          # print installing
          # aaa = rest_get('modules/get_module_info', { name: 'modA', namespace: module_ref.namespace })

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
        end
      end
    end
  end
end
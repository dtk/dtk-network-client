module DTK::Network
  module Client
    class Install
      def initialize(module_ref, options = {})
        @name      = module_ref[:name]
        @namespace = module_ref[:namespace]
        @version   = module_ref[:version]
        @options   = options
      end

      def run
        dependency_tree = DependencyTree.compute(@name, @namespace, @version)
        # ret module info and dependencies from dtk network
        # raise if errors
        # unless errors execute dependency calculations
        # when dependency calculations done write module_ref.lock file
        # read and parse module_refs.lock and install module
      end
    end
  end
end


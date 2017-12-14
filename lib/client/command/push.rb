module DTK::Network::Client
  class Command
    class Push < self
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

    end
  end
end
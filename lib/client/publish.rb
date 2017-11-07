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
      end
    end
  end
end
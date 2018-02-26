module DTK::Network::Client
  class Command
    class Update < self
      def initialize(module_ref, dependency_tree, options = {})
        @module_ref       = module_ref
        @dependency_tree  = dependency_tree
        @module_directory = module_ref.repo_dir
        @options          = options
        @parsed_module    = options[:parsed_module]
      end

      def self.run(module_info, opts = {})
        module_ref = ModuleRef.new(module_info)
        DependencyTree.get_or_create(module_ref, opts.merge(save_to_file: true, update_lock_file: true))
      end
    end
  end
end
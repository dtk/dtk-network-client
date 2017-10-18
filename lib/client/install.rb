module DTK::Network
  module Client
    class Install
      def initialize(module_ref, options = {})
        @name      = module_ref.module_name
        @namespace = module_ref.namespace
        @version   = module_ref.version
        @module_directory = module_ref.client_dir_path
        @options   = options
      end

      def run
        DependencyTree.new({ name: @name, namespace: @namespace, version: @version }, @options.merge(module_directory: @module_directory)).compute
        # require 'yaml'
        # content = dependency_tree.to_h.to_yaml
        # file_name = "#{@module_directory}/module_ref.lock"
        # FileUtils.mkdir_p(File.dirname(file_name))
        # File.open(file_name, 'w') { |f| f << content }
      end
    end
  end
end


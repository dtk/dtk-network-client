module DTK::Network
  module Client
    class Install
      def initialize(module_ref, options = {})
        @module_ref = module_ref
        @module_directory = module_ref.client_dir_path
        @options   = options
      end

      def run
        DependencyTree.new(@module_ref, @options.merge(module_directory: @module_directory)).compute
        # Session.rest_post(route, post_body = {})
        # require 'yaml'
        # content = dependency_tree.to_h.to_yaml
        # file_name = "#{@module_directory}/module_ref.lock"
        # FileUtils.mkdir_p(File.dirname(file_name))
        # File.open(file_name, 'w') { |f| f << content }
      end
    end
  end
end
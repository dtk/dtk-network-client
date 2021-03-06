module DTK::Network
  module Client
    class ModuleRef
      require_relative('module_ref/dependency')
      require_relative('module_ref/version')

      attr_reader :name, :namespace, :version, :repo_dir, :full_name, :explicit_path

      def initialize(module_info)
        @name            = module_info[:name]
        @namespace       = module_info[:namespace]
        mod_info_version = module_info[:version] || module_info['version']
        @version         = mod_info_version ? Version.new(mod_info_version) : nil
        @repo_dir        = module_info[:repo_dir]
        @explicit_path   = module_info[:explicit_path]
        @full_name       = "#{@namespace}/#{@name}"
      end
    end
  end
end


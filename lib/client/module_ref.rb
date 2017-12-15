module DTK::Network
  module Client
    class ModuleRef
      require_relative('module_ref/dependency')
      require_relative('module_ref/version')

      attr_reader :name, :namespace, :version, :repo_dir, :full_name

      def initialize(module_info)
        @name      = module_info[:name]
        @namespace = module_info[:namespace]
        @version   = module_info[:version] ? Version.new(module_info[:version]) : nil
        @repo_dir  = module_info[:repo_dir]
        @full_name = "#{@namespace}/#{@name}"
      end
    end
  end
end


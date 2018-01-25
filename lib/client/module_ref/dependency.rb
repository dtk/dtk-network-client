module DTK::Network::Client
  class ModuleRef
    class Dependency < self
      require_relative('dependency/local')
      require_relative('dependency/remote')

      include RestWrapper
      extend RestWrapper

      def self.create_local_or_remote(module_info)
        version = module_info[:version] || module_info['version']
        is_local?(version) ? Local.new(module_info) : Remote.new(module_info)
      end

      def self.is_local?(version)
        return unless version.is_a?(Hash)
        !!(version[:source] || version['source'])
      end
    end
  end
end
module DTK::Network::Client
  class Command
    class Info < self
      def initialize(module_ref, options = {})
        @module_ref = module_ref
        @about      = options[:about] || :versions
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        new(module_ref, opts).info
      end

      def info
        case @about.to_sym
        when :versions
          versions
        else
          module_info
        end
      end

      def versions
        modules_info = rest_get('modules/get_versions', { name: @module_ref.name, namespace: @module_ref.namespace })
        modules_info['versions'] || []
      end

      def module_info
      end
    end
  end
end

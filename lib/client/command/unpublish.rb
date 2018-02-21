module DTK::Network::Client
  class Command
    class Unpublish < self
      def initialize(module_ref, options = {})
        @module_ref       = module_ref
        @options          = options
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        new(module_ref, opts).unpublish
      end

      def unpublish
        version = @module_ref.version
        params = {
          name: @module_ref.name,
          namespace: @module_ref.namespace,
          version: version.str_version
        }
        rest_post("modules/unpublish", params)

        nil
      end
    end
  end
end

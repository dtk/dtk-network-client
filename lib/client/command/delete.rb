module DTK::Network::Client
  class Command
    class Delete < self
      def initialize(module_ref, options = {})
        @module_ref       = module_ref
        @options          = options
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        new(module_ref, opts).delete
      end

      def delete
        params = {
          name: @module_ref.name,
          namespace: @module_ref.namespace
        }
        rest_delete("modules/#{@module_ref.name}", params)

        nil
      end
    end
  end
end

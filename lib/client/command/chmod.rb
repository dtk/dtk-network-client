module DTK::Network::Client
  class Command
    class Chmod < self
      def initialize(namespace, permissions, options = {})
        @namespace   = namespace
        @permissions = permissions
      end

      def self.run(namespace, permissions, opts = {})
        new(namespace, permissions, opts).chmod
      end

      def chmod
        validate_permissions!(@permissions)
        rest_post("namespaces/#{@namespace}/chmod", { name: @namespace, permissions: @permissions })
        nil
      end

    end
  end
end
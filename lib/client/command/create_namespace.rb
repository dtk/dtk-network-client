module DTK::Network::Client
  class Command
    class CreateNamespace < self
      def initialize(namespace, options = {})
        @namespace = namespace
      end

      def self.run(namespace, opts = {})
        new(namespace, opts).create_namespace
      end

      def create_namespace
        rest_post("groups", { name: @namespace })
        nil
      end

    end
  end
end
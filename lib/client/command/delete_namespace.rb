module DTK::Network::Client
  class Command
    class DeleteNamespace < self
      def initialize(namespace, options = {})
        @namespace = namespace
      end

      def self.run(namespace, opts = {})
        new(namespace, opts).delete_namespace
      end

      def delete_namespace
        rest_delete("groups/#{@namespace}", { name: @namespace, reference: 'namespace' })
        nil
      end

    end
  end
end
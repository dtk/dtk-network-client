module DTK::Network::Client
  class Command
    class ListNamespaces < self
      def self.run(opts = {})
        namespaces = rest_get('namespaces')
        {'status' => 'ok', 'datatype' => 'remote_namespaces', 'data' => namespaces}
      end
    end
  end
end
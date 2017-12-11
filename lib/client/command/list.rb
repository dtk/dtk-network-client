module DTK::Network::Client
  class Command
    class List < self
      def self.run(namespace, opts = {})
        params = namespace ? {namespace: namespace} : {}
        modules_info = rest_get('modules', params)

        # return format expected by dtk-client, should change this to be more generic
        {'status' => 'ok', 'datatype' => 'remote_module', 'data' => modules_info}
      end
    end
  end
end

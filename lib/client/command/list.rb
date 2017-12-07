module DTK::Network::Client
  class Command
    class List < self
      def self.run(opts = {})
        modules_info = rest_get('modules')
        modules_info.merge!("status" => "ok", "datatype" =>"remote_module")
        modules_info
      end
    end
  end
end

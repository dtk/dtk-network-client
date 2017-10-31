module DTK::Network
  module Client
    class Conn
      def initialize
        @cookies = {}
        login
      end

      attr_reader :cookies

      def get(route, query_string_hash = {})
        url = rest_url(route)
        get_raw(url, query_string_hash)
      end

      def post(route, post_body = {})
        url = rest_url(route)        
        post_raw(url, post_body)
      end

      private

      REST_VERSION = 'v1'
      REST_PREFIX = "api/#{REST_VERSION}"

      def rest_url(route = nil)
        "#{rest_url_base}/#{REST_PREFIX}/#{route}"
      end

      def rest_url_base
        @@rest_url_base ||= Config.get_endpoint
      end

      def login
        response = post_raw rest_url('auth/sign_in'), get_credentials
        @cookies = response.cookies
      end

      def logout
        response = get_raw rest_url('auth/sign_out')
        # TODO: see if response can be nil
        raise Error, "Failed to logout, and terminate session!" unless response
        @cookies = nil
      end

      
      def get_credentials
        @parsed_credentials ||= Config.get_credentials
      end

      def default_rest_opts
        @default_rest_opts ||= get_default_rest_opts
      end

      def get_default_rest_opts
        {
          :timeout => 200,
          :open_timeout => 10,
          :verify_ssl => OpenSSL::SSL::VERIFY_PEER
        }
      end
      
      def get_raw(url, query_string_hash = {})
        RestClient::Resource.new(url, default_rest_opts.merge(cookies: @cookies)).get(params: query_string_hash)
      end

      def post_raw(url, post_body)
        RestClient::Resource.new(url, default_rest_opts.merge(cookies: @cookies)).post(post_body)
      end
    end
  end
end
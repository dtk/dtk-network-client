module DTK::Network
  module Client
    class Conn
      def initialize
        @cookies          = {}
        @connection_error = nil
        @codecommit       = nil
        login
      end

      attr_reader :cookies, :connection_error, :codecommit

      def get(route, query_string_hash = {})
        check_and_wrap_response { json_parse_if_needed(get_raw(rest_url(route), query_string_hash)) }
      end

      def post(route, post_body = {})
        check_and_wrap_response { json_parse_if_needed(post_raw(rest_url(route), post_body)) }
      end

      def delete(route, delete_body = {})
        check_and_wrap_response { json_parse_if_needed(delete_raw(rest_url(route), delete_body)) }
      end

      def connection_error?
        !connection_error.nil?
      end

      private

      def error_code?
        connection_error['errors'].first['code'] rescue nil
      end

      REST_VERSION = 'v1'
      REST_PREFIX = "api/#{REST_VERSION}"

      def rest_url(route = nil)
        "#{rest_url_base}/#{REST_PREFIX}/#{route}"
      end

      def rest_url_base
        @@rest_url_base ||= Config.get_endpoint
      end

      def check_and_wrap_response(&rest_method_func)
        if @connection_error
          raise Error, "Unable to connect to dtk network, please check your credentials and try again!"
        end

        response = rest_method_func.call

        # response

        # if Response::ErrorHandler.check_for_session_expiried(response)
        #   # re-logging user and repeating request
        #   OsUtil.print_warning("Session expired: re-establishing session & re-trying request ...")
        #   @cookies = Session.re_initialize
        #   response = rest_method_func.call
        # end


        # response_obj = Response.new(response)

        # queue messages from server to be displayed later
        #TODO: DTK-2554: put in processing of messages Shell::MessageQueue.process_response(response_obj)
        # response_obj
      end

      def login
        response = post_raw rest_url('auth/sign_in'), get_credentials
        if response.kind_of?(::DTK::Common::Response) and !response.ok?
          @connection_error = response
        else
          @cookies = response.cookies
          set_codecommit_info(response)
        end
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
        Response::RestClientWrapper.get_raw(url, query_string_hash, default_rest_opts.merge(:cookies => @cookies))
      end

      def post_raw(url, post_body, params = {})
        Response::RestClientWrapper.post_raw(url, post_body, default_rest_opts.merge(:cookies => @cookies).merge(params))
      end

      def delete_raw(url, delete_body, params = {})
        Response::RestClientWrapper.delete_raw(url, delete_body, default_rest_opts.merge(:cookies => @cookies).merge(params))
      end

      def json_parse_if_needed(item)
        Response::RestClientWrapper.json_parse_if_needed(item)
      end

      def set_codecommit_info(response)
        json_response = json_parse_if_needed(response)
        if codecommit_data = json_response.dig('data', 'meta', 'aws', 'codecommit')
          @codecommit = codecommit_data
        end
      end
    end
  end
end
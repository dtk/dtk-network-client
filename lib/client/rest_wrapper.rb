module DTK::Network::Client
  module RestWrapper
    def rest_get(url, params = {})
      raise_error_if_notok_response do
        Session.rest_get(url, params)
      end
    end

    def rest_post(url, post_body = {})
      raise_error_if_notok_response do
        Session.rest_post(url, post_body)
      end
    end

    private

    def raise_error_if_notok_response(&block)
      response = block.call
      if response
        status = response['status']
        if status
          raise Error.new(response) if status.eql?('notok')
          # response
        # else
          # Response::Ok.new(response)
        end
        response
      else
        raise Error.new(response)
      end
    end
  end
end
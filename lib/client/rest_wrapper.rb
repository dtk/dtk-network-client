module DTK::Network::Client
  module RestWrapper
    def rest_get(url, params = {})
      Session.rest_get(url, params)
    end

    def rest_post(url, post_body = {})
      Session.rest_post(url, post_body)
    end
  end
end
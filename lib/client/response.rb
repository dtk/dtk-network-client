require 'dtk_common_core' 

module DTK::Network::Client
  class Response < ::DTK::Common::Response
    require_relative('response/response_types')

    def initialize(hash = {})
      super(hash)
    end

    def notok?
      kind_of?(NotOk)
    end

    def self.wrap_as_response(data = {}, &block)
      results = (block ? yield : data)
      if results.nil?
        NoOp.new
      elsif results.kind_of?(Response)
        results
      else
        Ok.new(results)
      end
    end
  end
end


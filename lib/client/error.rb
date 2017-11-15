module DTK::Network::Client
  class Error < NameError
    def initialize(msg = '')
      super(msg)
    end
  end
end


module DTK::Network::Client
  class Error < NameError
    def initialize(msg = '')
      if errors = msg['errors']
      error_msg = ''
      # error_msg << "#{errors['code'].upcase} " if errors['code']
      error_msg << errors['message'] if errors['message']
      super(error_msg)
      else
        super(msg)
      end
    end
  end
end


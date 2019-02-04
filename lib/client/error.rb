module DTK::Network::Client
  class Error < NameError
    def initialize(msg = '')
      if errors = msg['errors']
        errors = [errors] unless errors.is_a?(Array)
        error_msg = ''
        # error_msg << "#{errors['code'].upcase} " if errors['code']
        errors.each do |error|
          if err_msg = error['message']
            error_msg << "#{err_msg}\n"
          elsif orig_exeption = error['original_exception']
            error_msg << "#{orig_exeption}\n"
          end
        end
        super(error_msg)
      else
        super(msg)
      end
    end

    class DependencyError < self
        def initialize(error_msg)
          errors = {
            'errors' => {
              'message' => error_msg
            }
          }
          super(errors)
        end
    end

  end
end


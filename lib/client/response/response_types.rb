module DTK::Network::Client
  class Response
    class Ok < self
      def initialize(data = {})
        super('data'=> data, 'status' => 'ok')
      end
    end
    
    class NotOk < self
      def initialize(data = {})
        super('data'=> data, 'status' => 'notok')
      end
    end
    
    class NoOp < self
      def render_data
      end
    end
    
    class ErrorResponse < self
      include ::DTK::Common::Response::ErrorMixin
      def initialize(hash = {})
        super('errors' => [hash])
      end
      private :initialize
      
      class Usage < self
        def initialize(hash_or_string = {})
          hash = (hash_or_string.kind_of?(String) ? {'message' => hash_or_string} : hash_or_string)
          super({'code' => 'error'}.merge(hash))
        end
      end
      
      class Internal < self
        def initialize(hash = {})
          super({'code' => 'error'}.merge(hash).merge('internal' => true))
        end
      end
    end
  end
end


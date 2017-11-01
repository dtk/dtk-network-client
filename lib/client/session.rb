require 'singleton'

module DTK::Network
  module Client
    class Session
      include Singleton

      attr_accessor :conn
      
      def initialize
        @conn = Conn.new
      end
      
      # opts can have keys
      #  :reset
      def self.get_connection(opts = {})
        instance.conn = Conn.new if opts[:reset]
        instance.conn
      end
      
      # def self.connection_username
      #   instance.conn.get_username
      # end
      
      def self.re_initialize
        instance.conn = nil
        instance.conn = Conn.new
        instance.conn.cookies
      end
      
      def self.logout
        # from this point @conn is not valid, since there are no cookies set
        instance.conn.logout
      end
      
      def self.rest_post(route, post_body = {})
        instance.conn.post(route, post_body)
      end

      def self.rest_get(route, opts = {})
        instance.conn.get(route, opts)
      end

    end
  end
end
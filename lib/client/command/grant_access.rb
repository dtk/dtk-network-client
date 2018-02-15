module DTK::Network::Client
  class Command
    class GrantAccess < self
      def initialize(namespace, user, options = {})
        @namespace = namespace
        @user      = user
      end

      def self.run(namespace, user, opts = {})
        new(namespace, user, opts).grant_access
      end

      def grant_access
        rest_post("groups/#{@namespace}/member", { name: @namespace, username: @user })
        nil
      end

    end
  end
end
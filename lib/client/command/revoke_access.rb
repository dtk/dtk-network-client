module DTK::Network::Client
  class Command
    class RevokeAccess < self
      def initialize(namespace, user, options = {})
        @namespace = namespace
        @user      = user
      end

      def self.run(namespace, user, opts = {})
        new(namespace, user, opts).revoke_access
      end

      def revoke_access
        rest_post("groups/#{@namespace}/remove_member", { name: @namespace, username: @user })
        nil
      end

    end
  end
end
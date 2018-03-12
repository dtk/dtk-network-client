module DTK::Network::Client
  class Command
    class RemoveFromGroup < self
      def initialize(group, user, options = {})
        @group = group
        @user      = user
      end

      def self.run(group, user, opts = {})
        new(group, user, opts).revoke_access
      end

      def revoke_access
        rest_post("groups/#{@group}/remove_member", { name: @group, username: @user })
        nil
      end

    end
  end
end
module DTK::Network::Client
  class Command
    class AddToGroup < self
      def initialize(group, user, options = {})
        @group = group
        @user      = user
      end

      def self.run(group, user, opts = {})
        new(group, user, opts).add_to_group
      end

      def add_to_group
        rest_post("groups/#{@group}/member", { name: @group, username: @user })
        nil
      end

    end
  end
end
module DTK::Network
  module Client
    class DependencyTree
      class Resolver
        def initialize(activated, dependencies)
          @children = activated[:children]
          @dependencies = dependencies
        end

        def resolve
          
        end
      end
    end
  end
end
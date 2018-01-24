module DTK::Network::Client
  class ModuleRef
    class Version
      class Source
        attr_reader :location
        def initialize(source)
          # right now we only support file as source, later we can introduce other sources
          if matching_source = source.match(/(file:)(.*)/)
            @location = matching_source[2]
          else
            fail "Unsuppored source format: #{source}!"
          end
        end
      end
    end
  end
end


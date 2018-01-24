module DTK::Network::Client
  class ModuleRef
    class Dependency
      class Local < self
        attr_reader :version, :source
        def initialize(module_info)
          super(name: module_info['module'], namespace: module_info['namespace'])
          version_hash   = module_info[:version] || module_info['version']
          version_str    = version_hash[:version] || version_hash['version']
          version_source = version_hash[:source] || version_hash['source']

          @version = ModuleRef::Version.new(version_str)
          @source  = find_source(version_source)
        end

        private

        def find_source(version_source)
          if matching_source = version_source.match(/(file:)(.*)/)
            matching_source[2]
          else
            fail "Unsuppored source format: #{version_source}!"
          end
        end
      end
    end
  end
end
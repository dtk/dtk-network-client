module DTK::Network::Client
  class ModuleRef
    class Dependency
      class Local < self
        MODULE_FILE = 'dtk.module.yaml'

        attr_reader :version, :source
        def initialize(module_info)
          super(name: module_info[:name] || module_info['module'], namespace: module_info[:namespace] || module_info['namespace'])
          version_hash   = module_info[:version] || module_info['version']
          version_str    = version_hash[:version] || version_hash['version']
          version_source = version_hash[:source] || version_hash['source']

          @version = ModuleRef::Version.new(version_str)
          @source  = find_source(version_source)
        end

        def dtkn_versions_with_dependencies
          require 'dtk_dsl'
          file_type         = DTK::DSL::FileType::CommonModule::DSLFile::Top
          file_obj          = DTK::DSL::FileObj.new(file_type, @source, { content: FileHelper.get_content?("#{@source}/#{MODULE_FILE}") })
          parsed_module     = file_obj.parse_content(:common_module_summary)
          dependent_modules = parsed_module.val(:DependentModules) || []

          dependencies = dependent_modules.map { |dep| { 'namespace' => dep[:namespace], 'module' => dep[:module_name], 'version' => dep[:version] }}
          [
            {
              'name' => self.version.str_version,
              'version' => self.version.str_version,
              'dependencies' => dependencies
            }
          ]
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
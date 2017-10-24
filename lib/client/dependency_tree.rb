require 'semverly'

module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')

      def initialize(module_ref, opts = {})
        @module_ref = module_ref
        @module_directory = opts[:module_directory]
        @activated  = Activated.new
        @opts = opts
      end

      def compute
        parsed_module = @opts[:parsed_module]

        dependencies = (parsed_module.val(:DependentModules) || []).map do |parsed_module_ref|
          dep_module_name = parsed_module_ref.req(:ModuleName)
          dep_namespace   = parsed_module_ref.req(:Namespace)
          dep_version     = parsed_module_ref.val(:ModuleVersion)
          {
            name: dep_module_name,
            namespace: dep_namespace,
            version: dep_version
          }
        end

        activate_dependencies(dependencies)

        content = @activated.to_h.to_yaml
        file_name = "#{@opts[:module_directory]}/module_ref.lock"
        FileUtils.mkdir_p(File.dirname(file_name))
        File.open(file_name, 'w') { |f| f << content }
      end

      def activate_dependencies(dependencies, opts = {})
        @session = @opts[:session]
        query_string_hash = {
          :detail_to_include => ['remotes', 'versions'],
          :rsa_pub_key => @opts[:rsa_pub_key],
          :module_namespace? => nil
        }
        module_list_response = @session.conn.get("modules/remote_modules", query_string_hash)
        @module_list = {}
        module_list_response.data.each { |mod| @module_list.merge!(mod['display_name'] => { name: mod['display_name'].split('/').last, namespace: mod['display_name'].split('/').first, versions: mod['versions']}) }

        dependencies.each do |dependency|
          dep_module_matching_versions = @module_list["#{dependency[:namespace]}/#{dependency[:name]}"]

          # check if any of those versions is already activated
          activated = @activated.contains_module?(dep_module_matching_versions)

          # if some of the versions is already activated then skip to next dependency
          next if activated

          # if same module activated but version does not match then deactivate module version and try with different one
          if existing_name = @activated.existing_name(dep_module_matching_versions[:name])
            throw :test
          end

          versions_activated = []
          if versions = dep_module_matching_versions[:versions]
            versions = versions.sort.reverse
            if versions.size > 1
              versions.delete('master')
            end
            versions.each do |version|
              next if versions_activated.include?(dep_module_matching_versions[:name])
              catch :test do
                latest_version = {
                  name: dep_module_matching_versions[:name],
                  namespace: dep_module_matching_versions[:namespace],
                  version: version
                }
                @activated.add(latest_version)

                # if matching versions are not activated send request with latest version to repoman route which takes module version and return dep_module info and dependencies
                # dep_module_with_deps_info = ModuleMock.ret(latest_version)
                dep_module_with_deps_info = latest_version.merge( dependencies: [] )

                hash = {
                  :module_name => dep_module_matching_versions[:name],
                  :namespace   => dep_module_matching_versions[:namespace],
                  :rsa_pub_key => @opts[:rsa_pub_key],
                  :version?    => version
                }
                response = @session.conn.get("modules/module_dependencies", hash)
                if required_modules = response.data(:required_modules)
                  dep_module_with_deps_info[:dependencies] += required_modules.map { |ref_hash| {
                    name: ref_hash['name'],
                    namespace: ref_hash['namespace'],
                    version: ref_hash['version'],
                    requirements: '='
                  } }
                end

                # iterate through dependencies of dependencies and repeat the same process
                dep_dependencies = dep_module_with_deps_info[:dependencies]
                unless dep_dependencies.empty?
                  activate_dependencies(dep_dependencies, parent: dep_module_with_deps_info)
                end
                versions_activated << dep_module_matching_versions[:name]
              end
            end
          end

        end
      end

      def select_latest(dep_module_matching_versions)
        if versions = dep_module_matching_versions[:versions]
          sorted_versions = versions.sort
          latest_version = sorted_versions.delete(sorted_versions.last)
          {
            name: dep_module_matching_versions[:name],
            namespace: dep_module_matching_versions[:namespace],
            version: latest_version
          }
        end
      end
    end
  end
end
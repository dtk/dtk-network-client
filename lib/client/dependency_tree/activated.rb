module DTK::Network
  module Client
    class DependencyTree
      class Activated < Hash
        def contains_module?(dependency_mod)
          name      = dependency_mod[:name]
          namespace = dependency_mod[:namespace]
          versions  = dependency_mod[:versions]
          exact_version(name, namespace, versions)
        end

        def add(dependency_mod)
          self.merge!(dependency_mod[:name] => { namespace: dependency_mod[:namespace], version: dependency_mod[:version]})
        end

        def delete(dependency_mod)
          self.delete(dependency_mod[:name])
        end

        def existing_name(name)
          self[name]
        end

        private

        def exact_version(name, namespace, versions)
          matching_mod = existing_name(name)
          return unless matching_mod

          matching_mod_version = matching_mod[:version]
          if matching_version = matching_mod[:namespace].eql?(namespace) && versions.find { |version| matching_mod_version.eql?(version) }
            return { name: name, namespace: namespace, version: matching_version }
          end
        end
      end
    end
  end
end
module DTK::Network
    module Client
      class DependencyTree
        class Activated < Hash
          def contains_module?(dependency_mod)
            name      = dependency_mod[:name]
            namespace = dependency_mod[:namespace]
            versions  = dependency_mod[:versions]
            if matching_mod = self[name]
              if matching_mod[:namespace].eql?(namespace)
                if matching_version = versions.find { |version| matching_mod[:version].eql?(version) }
                  return { name: name, namespace: namespace, version: matching_version }
                end
              end
            end
          end
        end
      end
    end
  end
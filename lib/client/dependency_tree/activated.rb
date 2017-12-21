module DTK::Network
  module Client
    class DependencyTree
      class Activated < Hash
        def module_activated?(dependency)
          if existing_dep = self["#{dependency.full_name}"]
            if required_version = dependency.version
              required_version.satisfied_by?(existing_dep[:version] || existing_dep['version'])
            end
          end
        end

        def add!(dependency_mod)
          self.merge!("#{dependency_mod.full_name}" => { 'version' => dependency_mod.version.str_version })
        end

        def existing_name?(name)
          self[name]
        end

        def delete!(dependency_mod)
          self.delete(dependency_mod.full_name)
        end
      end
    end
  end
end
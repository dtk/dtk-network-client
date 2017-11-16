module DTK::Network
  module Client
    class DependencyTree
      class Candidates < Hash
        def add!(dependency_mod, versions)
          self.merge!(dependency_mod.full_name => { 'dependency_obj' => dependency_mod, 'versions' => versions })
        end

        # def existing_name?(name)
        #   self[name]
        # end

        # def delete!(dependency_mod)
        #   self.delete(dependency_mod.full_name)
        # end
      end
    end
  end
end
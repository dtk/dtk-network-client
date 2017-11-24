require 'semverly'

module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')
      require_relative('dependency_tree/cache')
      require_relative('dependency_tree/candidates')

      include RestWrapper
      extend RestWrapper

      LOCK_FILE = "module_ref.lock"

      def initialize(module_ref, opts = {})
        @module_ref       = module_ref
        @module_directory = opts[:module_directory] || module_ref.repo_dir
        @parsed_module    = opts[:parsed_module]
        @cache            = Cache.new
        @activated        = Activated.new
        @candidates       = Candidates.new
      end

      def self.get_dependency_tree(module_ref, opts = {})
        if content = FileHelper.get_content?("#{module_ref.repo_dir}/#{LOCK_FILE}")
          ret_as_module_refs(YAML.load(content))
        else
          ret_as_module_refs(compute_and_save_to_file(module_ref, opts))
        end
      end

      def self.compute_and_save_to_file(module_ref, opts = {})
        activated = compute(module_ref, opts)
        ModuleDir.create_file_with_content("#{module_ref.repo_dir}/#{LOCK_FILE}", YAML.dump(activated.to_h))
        activated
      end

      def self.compute(module_ref, opts = {})
        new(module_ref, opts).compute
      end

      def compute
        dependencies = (ret_dependencies || []).map do |pm_ref|
          ModuleRef::Dependency.new({ name: pm_ref['module'], namespace: pm_ref['namespace'], version: pm_ref['version'] })
        end

        activate_dependencies(dependencies)
        @activated
      end

      private

      def activate_dependencies(dependencies, opts = {})
        dependencies.each do |dependency|
          next if @activated.module_activated?(dependency)

          check_for_conflicts(dependency)

          dtkn_versions_w_deps_hash = dtkn_versions_with_dependencies(dependency)
          dtkn_versions_w_deps = dtkn_versions_w_deps_hash.map { |v| v['version'] }

          version_obj = dependency.version
          versions_in_range = version_obj.versions_in_range(dtkn_versions_w_deps)

          raise "No version matching requirement '#{version_obj.full_version}'" if versions_in_range.empty?

          versions_in_range.sort!
          latest_version = versions_in_range.last
          latest_version_dep = ModuleRef::Dependency.new({ name: dependency.name, namespace: dependency.namespace, version: latest_version })

          @activated.add!(latest_version_dep)
          @candidates.add!(dependency, versions_in_range)

          dtkn_deps_of_deps = dtkn_versions_w_deps_hash.find {|dep| dep['version'].eql?(latest_version) }
          dtkn_deps_of_deps_objs = (dtkn_deps_of_deps['dependencies'] || {}).map do |dtkn_dep|
            ModuleRef::Dependency.new({ name: dtkn_dep['module'], namespace: dtkn_dep['namespace'], version: dtkn_dep['version'] })
          end

          activate_dependencies(dtkn_deps_of_deps_objs, opts)
        end
      end

      def ret_dependencies
        if @parsed_module
          (@parsed_module.val(:DependentModules) || []).map do |parsed_mr|
            { 'namespace' => parsed_mr.req(:Namespace), 'module' => parsed_mr.req(:ModuleName), 'version' => parsed_mr.val(:ModuleVersion) }
          end
        else
          response = rest_get('modules/dependencies_for_name', { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version })
          response['dependencies']
        end
      end

      def dtkn_versions_with_dependencies(module_ref)
        response = rest_get("modules/get_versions_with_dependencies", { name: module_ref.name, namespace: module_ref.namespace })
        response['versions_w_deps']
      end

      def check_for_conflicts(dependency)
        if activated_mod = @activated.existing_name?(dependency.full_name)
          raise "There is already activated version '#{activated_mod[:version]}' for module '#{dependency.full_name}' and it does not match required version '#{dependency.version.full_version}'"
        end
      end

      def self.ret_as_module_refs(dep_modules)
        dep_modules.map { |k,v| create_module_ref(k, v) }
      end

      def self.create_module_ref(full_name, version_hash)
        namespace, name = full_name.split('/')
        ModuleRef.new({ namespace: namespace, name: name, version: version_hash[:version] })
      end

    end
  end
end
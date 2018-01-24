require 'semverly'

module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')
      require_relative('dependency_tree/cache')
      require_relative('dependency_tree/candidates')

      include RestWrapper
      extend RestWrapper

      LOCK_FILE = "dtk.module.lock"

      def initialize(module_ref, opts = {})
        @module_ref       = module_ref
        @module_directory = opts[:module_directory] || module_ref.repo_dir
        @parsed_module    = opts[:parsed_module]
        @cache            = Cache.new
        @activated        = Activated.new
        @candidates       = Candidates.new
      end

      def self.get_or_create(module_ref, opts = {})
        content = nil
        module_ref = convert_to_module_ref(module_ref) unless module_ref.is_a?(ModuleRef)

        if yaml_content = FileHelper.get_content?("#{module_ref.repo_dir}/#{LOCK_FILE}")
          content = YAML.load(yaml_content)
        elsif opts[:save_to_file]
          content = compute_and_save_to_file(module_ref, opts)
        else
          content = compute(module_ref, opts)
        end

        ret_required_format(content, opts[:format])
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
          ModuleRef::Dependency.create_local_or_remote(pm_ref)
          # ModuleRef::Dependency.new({ name: pm_ref['module'], namespace: pm_ref['namespace'], version: pm_ref['version'] })
          # ModuleRef::Dependency.new({ name: pm_ref['module'], namespace: pm_ref['namespace'], version: pm_ref['version'] })
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
          add_nested_modules(dependency, dtkn_deps_of_deps)

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
          response = rest_get("modules/#{@module_ref.name}/dependencies", { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version.str_version })
          response['dependencies']
        end
      end

      def dtkn_versions_with_dependencies(module_ref)
        response = rest_get("modules/get_versions_with_dependencies", { name: module_ref.name, namespace: module_ref.namespace })
        response['versions']
      end

      def check_for_conflicts(dependency)
        if activated_mod = @activated.existing_name?(dependency.full_name)
          raise "There is already activated version '#{activated_mod[:version]}' for module '#{dependency.full_name}' and it does not match required version '#{dependency.version.full_version}'"
        end
      end

      def add_nested_modules(dependency, dtkn_deps_of_deps)
        if activated_module = @activated[dependency.full_name]
          nested_deps = {}
          (dtkn_deps_of_deps['dependencies'] || []).each{ |dtkn_dep| nested_deps.merge!("#{dtkn_dep['namespace']}/#{dtkn_dep['module']}" => dtkn_dep['version']) }

          unless nested_deps.empty?
            activated_module.key?('modules') ? activated_module['modules'].merge!(nested_deps) : activated_module.merge!('modules' => nested_deps)
          end
        end
      end

      def self.ret_as_module_refs(dep_modules)
        dep_modules.map { |k,v| create_module_ref(k, v) }
      end

      def self.create_module_ref(full_name, version_hash)
        namespace, name = full_name.split('/')
        version = version_hash[:version] || version_hash['version']
        ModuleRef.new({ namespace: namespace, name: name, version: version })
      end

      def self.ret_as_hash(dep_modules)
        dep_modules.map { |k,v| create_module_hash(k, v) }
      end

      def self.create_module_hash(full_name, version_hash)
        namespace, name = full_name.split('/')
        version = version_hash[:version] || version_hash['version']
        { namespace: namespace, name: name, version: version }
      end

      def self.ret_required_format(content, format)
        format ||= :module_ref
        case format.to_sym
        when :module_ref
          ret_as_module_refs(content)
        when :hash
          ret_as_hash(content)
        else
          raise Error.new("Unsupported format '#{format}'. Valid formats are '#{ValidFormats.join(', ')}'")
        end
      end
      ValidFormats = [:module_ref, :hash]

      def self.convert_to_module_ref(module_ref)
        ModuleRef.new(module_ref)
      end

    end
  end
end
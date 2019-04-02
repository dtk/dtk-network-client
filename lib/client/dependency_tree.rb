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
        @module_ref          = module_ref
        @module_directory    = opts[:module_directory] || module_ref.repo_dir
        @parsed_module       = opts[:parsed_module]
        @cache               = Cache.new
        @activated           = Activated.new
        @candidates          = Candidates.new
        @development_mode    = opts[:development_mode]
        @server_dependencies = opts[:server_dependencies]
      end

      def self.get_or_create(module_ref, opts = {})
        content          = nil
        module_ref       = convert_to_module_ref(module_ref) unless module_ref.is_a?(ModuleRef)
        update_lock_file = opts[:update_lock_file]
        yaml_content     = FileHelper.get_content?("#{module_ref.repo_dir}/#{LOCK_FILE}")

        if yaml_content && !update_lock_file
          content = YAML.load(yaml_content)
          raise_error_if_dependencies_changed!(content, opts[:parsed_module])
        elsif opts[:save_to_file] || update_lock_file
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
        end

        activate_dependencies(dependencies)
        @activated

        sort_activated_dependencies(@activated)
      end

      private

      def activate_dependencies(dependencies, opts = {})
        dependencies.each do |dependency|
          next if @activated.module_activated?(dependency)

          puts "Calculating dependencies for module: #{dependency.full_name}(#{dependency.version.str_version})" if @development_mode

          check_for_conflicts(dependency)

          # first check if module is installed on server
          if dtkn_versions_w_deps_hash = @server_dependencies && !@server_dependencies.empty? && @server_dependencies["#{dependency.namespace}/#{dependency.name}"]
            dtkn_versions_w_deps = dtkn_versions_w_deps_hash.map { |v| v['version'] }
            versions_in_range = dependency.version.versions_in_range(dtkn_versions_w_deps)
          end

          if versions_in_range.nil? || versions_in_range.empty?
            dtkn_versions_w_deps_hash = dependency.dtkn_versions_with_dependencies
            dtkn_versions_w_deps = dtkn_versions_w_deps_hash.map { |v| v['version'] }
            version_obj = dependency.version
            versions_in_range = version_obj.versions_in_range(dtkn_versions_w_deps)
          end

          # dtkn_versions_w_deps_hash = dtkn_versions_with_dependencies(dependency)
          # dtkn_versions_w_deps_hash = dependency.dtkn_versions_with_dependencies
          # dtkn_versions_w_deps = dtkn_versions_w_deps_hash.map { |v| v['version'] }

          # version_obj = dependency.version
          # versions_in_range = version_obj.versions_in_range(dtkn_versions_w_deps)

          raise "No version matching requirement '#{version_obj.full_version}' for dependent module '#{dependency.full_name}'" if versions_in_range.empty?

          versions_in_range.sort!
          latest_version = versions_in_range.last

          if dependency.is_a?(ModuleRef::Dependency::Local)
            latest_version_dep = dependency
          else
            latest_version_dep = ModuleRef::Dependency::Remote.new({ name: dependency.name, namespace: dependency.namespace, version: latest_version })
          end

          @activated.add!(latest_version_dep)
          @candidates.add!(dependency, versions_in_range)

          dtkn_deps_of_deps = dtkn_versions_w_deps_hash.find {|dep| dep['version'].eql?(latest_version) }
          add_nested_modules(dependency, dtkn_deps_of_deps)

          dtkn_deps_of_deps_objs = (dtkn_deps_of_deps['dependencies'] || {}).map do |dtkn_dep|
            ModuleRef::Dependency.create_local_or_remote({ name: dtkn_dep['module'], namespace: dtkn_dep['namespace'], version: dtkn_dep['version'] })
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
          raise Error::DependencyError, "There is already activated version '#{activated_mod[:version] || activated_mod['version']}' for module '#{dependency.full_name}' and it does not match required version '#{dependency.version.full_version}'"
        end
      end

      def add_nested_modules(dependency, dtkn_deps_of_deps)
        if activated_module = @activated[dependency.full_name]
          nested_deps = {}
          (dtkn_deps_of_deps['dependencies'] || []).each{ |dtkn_dep| nested_deps.merge!("#{dtkn_dep['namespace']}/#{dtkn_dep['module']}" => simplify_version(dtkn_dep['version'])) }

          unless nested_deps.empty?
            activated_module.key?('modules') ? activated_module['modules'].merge!(nested_deps) : activated_module.merge!('modules' => nested_deps)
          end
        end
      end

      def simplify_version(version)
        if version.is_a?(Hash)
          # transform custom dtk hash into ruby hash to avoid strange output in yaml file
          version.to_h
        else
          version
        end
      end

      def sort_activated_dependencies(activated_deps)
        ret_hash = {}

        activated_deps.each do |k, activated_dep|
          ret_hash.merge!({ k => activated_dep })
          if modules = (activated_dep[:modules] || activated_dep['modules'])
            modules.each { |name, _content| ret_hash = {name => activated_deps[name]}.merge(ret_hash) }
          end
        end

        ret_hash
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
        ret = { namespace: namespace, name: name, version: version }

        if source = version_hash[:source] || version_hash['source']
          ret.merge!(source: source)
        end

        if modules = version_hash[:modules] || version_hash['modules']
          ret.merge!(modules: modules)
        end

        ret
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

      def self.raise_error_if_dependencies_changed!(lock_content, parsed_module)
        return unless parsed_module

        message      = "Module dependencies have been changed, please use '-u' option to update '#{LOCK_FILE}' file accordingly."
        dependencies = convert_to_modules_lock_format(parsed_module.val(:DependentModules))

        lock_deps = filter_out_dependencies_of_dependencies(lock_content, dependencies)
        raise Error.new(message) if dependencies.size != lock_deps.size

        dependencies.each do |name, value|
          if matching = lock_deps[name]
            module_ref_version = ModuleRef::Version.new(value['version'])
            matches_version = module_ref_version.satisfied_by?(matching['version'])
            matches_source = (value['source'] == matching['source'])
            raise Error.new(message) unless (matches_version && matches_source)
          else
            raise Error.new(message)
          end
        end
      end

      def self.convert_to_modules_lock_format(dependencies = {})
        modules_hash = {}

        (dependencies || {}).each do |dependency|
          version = dependency[:version]
          source  = nil

          if version.is_a?(Hash)
            source = version['source'] || version[:source]
            if matching_source = source && source.match(/(file:)(.*)/)
              source = matching_source[2]
            end
            version = version['version'] || version[:version]
          end

          namespace_name = "#{dependency[:namespace]}/#{dependency[:module_name]}"
          content_hash = {'version' => version}
          content_hash['source'] = source if source
          modules_hash.merge!(namespace_name => content_hash)
        end

        modules_hash
      end

      def self.filter_out_dependencies_of_dependencies(lock_content, module_yaml_dependencies)
        top_level_dependencies = {}
        nested_dependencies    = {}

        lock_content.each do |lock_name, lock_value|
          nested_dependencies.merge!(lock_value['modules'] || lock_value[:modules] || {})
          top_level_dependencies.merge!(lock_name => {'version' => lock_value['version'], 'source' => lock_value['source']})
        end

        nested_dependencies.each do |nd_name, version|
          source = nil

          if version.is_a?(Hash)
            source  = version['source']  || version[:source]
            version = version['version'] || version[:version]
          end

          if top_level_dependency = top_level_dependencies[nd_name]
            module_ref_version = ModuleRef::Version.new(version)
            matches_version    = module_ref_version.satisfied_by?(top_level_dependency['version'])
            matches_source     = (source == top_level_dependency['source'])

            if yaml_dep = module_yaml_dependencies[nd_name]
              matches_version_new = module_ref_version.satisfied_by?(yaml_dep['version']) || module_ref_version.full_version == yaml_dep['version']
              matches_source_new  = (source == yaml_dep['source'])
              next if (matches_version_new && matches_source_new)
            end

            top_level_dependencies.delete(nd_name) if (matches_version && matches_source)
          end
        end

        top_level_dependencies
      end

    end
  end
end

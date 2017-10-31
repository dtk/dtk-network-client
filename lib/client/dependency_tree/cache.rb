module DTK::Network::Client
  class DependencyTree
    class Cache < ::Hash
      def initialize
        super()
      end

      def add!(module_ref, dependencies)
        self[index(module_ref)] ||= {:module_ref => module_ref, :dependencies => dependencies }
      end

      def lookup_dependencies?(module_ref)
        (self[index(module_ref)] || {})[:dependencies]
      end

      def all_modules_refs
        values.map { |hash| hash[:module_ref] }
      end

      private

      def index(module_ref)
        "#{module_ref.module_name}--#{module_ref.namespace}--#{module_ref.version}"
      end

    end
  end
end

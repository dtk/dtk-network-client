module DTK::Network::Client
  class ModuleRef
    class Version
      attr_reader :full_version, :requirement, :semantic_version, :str_version

      def initialize(version = '')
        @full_version     = version.strip
        @str_version      = ''
        @requirement      = '='
        @semantic_version = nil
        parse
      end

      def versions_in_range(versions)
        v_in_range = []
        versions   = [versions] unless versions.is_a?(Array)

        versions.each do |version|
          if satisfied_by?(version)
            v_in_range << version
          end
        end

        v_in_range
      end

      def satisfied_by?(version = nil)
        return unless version
        match_requirement?(version)
      end

      def is_semantic_version?
        !!@semantic_version
      end

      private

      def match_requirement?(version)
        case @requirement
        when '='
          version == @str_version
        when '<'
          version < @str_version
        when '>'
          version > @str_version
        when '<='
          version <= @str_version
        when '>='
          version >= @str_version
        when '~>'
          top_version = nil

          if patch = @semantic_version.patch
            top_version = "#{@semantic_version.major}.#{@semantic_version.minor + 1}.0"
          elsif minor = @semantic_version.minor
            top_version = "#{@semantic_version.major + 1}.0.0"
          end

          return false unless top_version

          (version < top_version) && (version >= @str_version)
        else
          false
        end
      end

      def parse
        parsed = @full_version.split(' ')
        raise "Invalid version #{@full_version}!" if parsed.empty? || parsed.size > 2

        if parsed.size == 1
          @str_version = parsed.first
          @semantic_version = SemVer.parse(@str_version)
        else
          @requirement      = parsed.first
          @str_version      = parsed.last
          @semantic_version = SemVer.parse(@str_version)
        end
      end
    end
  end
end


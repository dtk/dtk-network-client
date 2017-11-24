module DTK::Network
  module Client
    class Args < ::Hash
      def initialize(hash = {})
        replace(hash)
      end

      def self.convert(ruby_hash_or_args)
        ruby_hash_or_args.kind_of?(Args) ? ruby_hash_or_args : new(ruby_hash_or_args)
      end

      def required(key)
        if has_key?(key)
          self[key]
        else
          raise "Args object missing the key '#{key}'"
        end
      end
    end
  end
end



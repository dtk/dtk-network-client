require 'fileutils'

module DTK::Network::Client
  class Config
    extend DTK::Network::Client::Util::OsUtil

    DTK_NETWORK_FILE   = '.dtk_network'
    DTK_NETWORK_CONFIG = File.join(dtk_local_folder, DTK_NETWORK_FILE)

    def self.get_credentials
      raise "Dtk network config file (#{DTK_NETWORK_CONFIG}) does not exist" unless File.exists?(DTK_NETWORK_CONFIG)
      ret = parse_key_value_file(DTK_NETWORK_CONFIG)
      [:email, :password].each{ |k| raise "cannot find #{k}" unless ret[k] }
      {
        email: ret[:email],
        password: ret[:password]
      }
    end

    def self.get_endpoint
      raise "Dtk network config file (#{DTK_NETWORK_CONFIG}) does not exist" unless File.exists?(DTK_NETWORK_CONFIG)
      ret = parse_key_value_file(DTK_NETWORK_CONFIG)
      [:endpoint, :port].each{ |k| raise "cannot find #{k}" unless ret[k] }
      "#{ret[:endpoint]}:#{ret[:port]}"
    end
    
    def self.parse_key_value_file(file)
      raise "Config file (#{file}) does not exists" unless File.exists?(file)

      ret = Hash.new
      File.open(file).each do |line|
        # strip blank spaces, tabs etc off the end of all lines
        line.gsub!(/\s*$/, "")
        unless line =~ /^#|^$/
          if (line =~ /(.+?)\s*=\s*(.+)/)
            key = $1
            val = $2
            ret[key.to_sym] = val
          end
        end
      end

      ret
    end

  end
end

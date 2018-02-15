module DTK::Network::Client
  class Storage
    module Adapter
      class S3
        require 'aws-sdk'

        def initialize(data_hash)
          @s3 = Aws::S3::Client.new(data_hash)
        end

        def upload(data_hash)
          @s3.put_object(data_hash)
        end

        def download(data_hash, opts = {})
          @s3.get_object(data_hash, opts)
        end

        def delete(data_hash, opts = {})
          @s3.delete_object(data_hash, opts)
        end
      end
    end
  end
end
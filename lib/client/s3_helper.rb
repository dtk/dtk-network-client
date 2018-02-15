module DTK::Network::Client
  class S3Helper
    def self.ret_s3_bucket_info(response)
      branch = response['branch'] || {}
      bucket = nil
      object_name = nil

      if meta = branch['meta']
        catalog_uri = meta['catalog_uri']
        if match = catalog_uri.match(/.*amazonaws.com\/([^\/]*)\/(.*.gz)/)
          bucket = match[1]
          object_name = match[2]
        end
      else
        raise "Unexpected that publish response does not contain branch metadata!"
      end

      raise "Unable to extract bucket and/or object name data from catalog_uri!" if bucket.nil? || object_name.nil?

      return [bucket, object_name]
    end
  end
end

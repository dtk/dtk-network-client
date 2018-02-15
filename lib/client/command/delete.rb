module DTK::Network::Client
  class Command
    class Delete < self
      def initialize(module_ref, options = {})
        @module_ref       = module_ref
        @options          = options
      end

      def self.run(module_info, opts = {})
        module_ref      = ModuleRef.new(module_info)
        new(module_ref, opts).delete
      end

      def delete
        require 'byebug'
        byebug
        delete_info = rest_get("modules/delete_info", { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version.str_version })
        delete_creds = delete_info['delete_credentails']
        bucket, object_name = S3Helper.ret_s3_bucket_info(delete_info)

        s3_args = Args.new({
          region: 'us-east-1',
          access_key_id: delete_creds['access_key_id'],
          secret_access_key: delete_creds['secret_access_key'],
          session_token: delete_creds['session_token']
        })
        storage = Storage.new(:s3, s3_args)

        delete_args = Args.new({
          bucket: bucket,
          key: object_name
        })
        # storage.delete(delete_args)
require 'byebug'
byebug
        branch_id = delete_info.dig('branch', 'id')
        delete_info = rest_delete("branches/#{branch_id}")
delete_info
        nil
      end
    end
  end
end

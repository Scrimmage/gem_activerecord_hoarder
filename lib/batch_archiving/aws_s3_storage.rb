module BatchArchiving
  class AwsS3
    DEFAULT_ACL = "private"
    OPTION_CONTENT_ACCESS = "acl"
    OPTION_SUB_DIR = "bucket_sub_dir"
    OPTION_BUCKET = "bucket"
    OPTION_ACCESS_KEY_ID = "access_key_id"
    OPTIONS_SECRET_ACCESS_KEY = "secret_access_key"
    OPTION_REGION = "region"

    attr_reader :storage_options

    def initialize(table_name, storage_options)
      @storage_options = storage_options

      if storage_options[OPTION_SUB_DIR].blank?
        @key_prefix = table_name
      else
        @key_prefix = File.join(storage_options[OPTION_SUB_DIR], table_name)
      end
    end

    def fetch_data(key)
      full_key = key_with_prefix(key)
      begin
        response = s3_client.get_object(bucket: s3_bucket, key: full_key)
      rescue Aws::S3::Errors::NoSuchKey => e
        raise ::BatchArchiving::StorageError.new("fetch_data erred with '#{e.class}':'#{e.message}'' trying to access '#{full_key}'' in bucket: '#{s3_bucket}'")
      end
      response.body
    end

    def store_data(batch)
      full_key = key_with_prefix(batch.key.to_s)

      s3_client.put_object(bucket: s3_bucket, body: batch.content_string, key: full_key, acl: s3_acl)
      true
    end

    private

    def key_with_prefix(key)
      File.join(@key_prefix, key.to_s)
    end

    def s3_acl
      storage_options[OPTION_CONTENT_ACCESS] || DEFAULT_ACL
    end

    def s3_bucket
      storage_options[OPTION_BUCKET]
    end

    def s3_client
      @s3_client ||= begin
        access_key_id = storage_options[OPTION_ACCESS_KEY_ID] or raise StorageError.new("access_key_id missing")
        secret_access_key = storage_options[OPTIONS_SECRET_ACCESS_KEY] or raise StorageError.new("secret_access_key missing")
        credentials = Aws::Credentials.new(access_key_id, secret_access_key)
        region = storage_options[OPTION_REGION] or raise StorageError.new("region missing")
        Aws::S3::Client.new(credentials: credentials, region: region)
      end
    end
  end
end

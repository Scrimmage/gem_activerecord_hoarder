class ::BatchArchiving::AwsS3
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

  def store_archive(batch)
    acl = storage_options[OPTION_CONTENT_ACCESS] || s3_acl || DEFAULT_ACL
    bucket = storage_options[OPTION_BUCKET] || s3_bucket
    full_key = key_with_prefix(batch.key.to_s)

    s3_client.put_object(bucket: bucket, body: batch.to_s, key: full_key, acl: acl)
    true
  end

  private

  def key_with_prefix(key)
    File.join(@key_prefix, key.to_s)
  end

  def s3_acl
    @s3_acl ||= storage_options[OPTION_CONTENT_ACCESS]
  end

  def s3_bucket
    @s3_bucket ||= storage_options[OPTION_BUCKET]
  end

  def s3_client
    @s3_client ||= begin
      access_key_id = storage_options[OPTION_ACCESS_KEY_ID]
      secret_access_key = storage_options[OPTIONS_SECRET_ACCESS_KEY]
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      region = storage_options[OPTION_REGION]
      Aws::S3::Client.new(credentials: credentials, region: region)
    end
  end
end

class ::BatchArchiving::AwsS3
  attr_reader :storage_options

  def initialize(model, storage_options)
    @storage_options = storage_options

    record_name = model.to_s.downcase.pluralize

    if storage_options["bucket_sub_dir"].blank?
      @key_prefix = record_name
    else
      @key_prefix = File.join(storage_options["bucket_sub_dir"], record_name)
    end
  end

  def store_archive(key_sequence:, content:, options: {})
    storage_key = File.join(@key_prefix, key_sequence)
    put_options = storage_options.merge(options)

    s3_client.put_object(body: content, key: storage_key, **put_options)
  end

  private

  def s3_bucket
    @s3_bucket ||= storage_options["bucket"]
  end

  def s3_client
    @s3_client ||= begin
      access_key_id = storage_options["access_key_id"]
      secret_access_key = storage_options["secret_access_key"]
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      region = storage_options["region"]
      Aws::S3::Client.new(credentials: credentials, region: region)
    end
  end
end

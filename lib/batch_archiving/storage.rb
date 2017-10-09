class ::BatchArchiving::Storage
  def self.configure(storage:, storage_options:)
    @@storage_options = storage_options

    class << self
      attr_reader :storage_options
    end

    if storage == :aws_s3
      extend ::BatchArchiving::AwsS3
    elsif storage == :local
      extend ::BatchArchiving::Local
    else
      raise "unknown storage (#{storage})"
    end
  end
end

module ::BatchArchiving::AwsS3
  def self.store_archive(archive_content:, storage_key:, access_control: nil)
    if access_control.nil?
      access_control = self.class.storage_options["acl"]
    end
    s3_client.put_object(acl: access_control, body: archive_content, bucket: s3_bucket, key: storage_key)
  end

  def self.retrieve_records_from_archive(prefix:, date_range: nil)
  end

  def initialize(model)
    @model = model
  end

  def retrieve_records_from_archive
  end

  def store_archive(key_sequence:, content:, options: {})
    storage_key = File.join(key_sequence)
    self.class.store_archive(archive_content: content, storage_key: storage_key, access_control: options["acl"])
  end

  private

  def s3_bucket
    @s3_bucket ||= self.class.storage_options["bucket"]
  end

  def s3_client
    @s3_client ||= begin
      access_key_id = self.class.storage_options["access_key_id"]
      secret_access_key = self.class.storage_options["secret_access_key"]
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      region = self.class.storage_options["region"]
      Aws::S3::Client.new(credentials: credentials, region: region)
    end
  end
end

module ::BatchArchiving::Local
  def self.store_archive
  end

  def self.retrieve_records_from_archive
  end

  def initialize(model)
  end

  def retrieve_records_from_archive
  end

  def store_archive
  end
end

module ::BatchArchiving::ConfigTemplate = "
storage_config:
  client_config:
    region: <region>
    credentials:
      access_key_id: <access_key_id>
      secret_access_key: <secret_access_key>
  acl: <acl>
  bucket: <bucket>
  "

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
    s3_client.put_object(acl: access_control, body: archive_content, bucket: s3_bucket, key: storage_key)
  end

  def self.retrieve_records_from_archive(prefix:, date_range: nil)
  end

  def initialize(model)
    @model = model
  end

  def retrieve_records_from_archive
  end

  def store_archive
  end

  private

  def s3_bucket
    @s3_bucket ||= self.class.storage_options["bucket"]
  end

  def s3_client
    @s3_client ||= do
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

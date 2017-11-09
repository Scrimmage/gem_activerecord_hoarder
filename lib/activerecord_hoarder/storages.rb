module ::ActiverecordHoarder
  class Storages
    STORAGE_DICT = {
      aws_s3: ::ActiverecordHoarder::AwsS3
    }

    def self.check_storage(storage_key)
      raise ::ActiverecordHoarder::StorageError.new("unknown storage (#{storage_key}), known keys are #{STORAGE_DICT.keys}") if !is_valid_storage?(storage_key)
    end

    def self.is_valid_storage?(storage_key)
      STORAGE_DICT.keys.include?(storage_key)
    end

    def self.retrieve(storage_key)
      check_storage(storage_key)
      STORAGE_DICT[storage_key]
    end
  end
end

module ::BatchArchiving
  class Batch
    RECORD_DATE_FIELD = "created_at"

    def self.from_records(record_data)
      record_data.present? ? new(record_data) : nil
    end

    def initialize(record_data)
      @record_data = record_data
      @serializer = ::BatchArchiving::Serializer
    end

    def date
      @date ||= @record_data.first[RECORD_DATE_FIELD].to_date
    end

    def key
      @key ||= ::BatchArchiving::StorageKey.from_date(date, @serializer.extension)
    end

    def content_string
      @serializer.create_archive(@record_data)
    end
  end
end

module ::ActiverecordHoarder
  class Batch
    RECORD_DATE_FIELD = "created_at"

    def self.from_records(record_data, **kwargs)
      record_data.present? ? new(record_data, **kwargs) : nil
    end

    def initialize(record_data, database_connection: nil, deletion_query: nil)
      @record_data = record_data
      @serializer = ::ActiverecordHoarder::Serializer
      @database_connection = database_connection
      @deletion_query = deletion_query
    end

    def content_string
      @serializer.create_archive(@record_data)
    end

    def date
      @date ||= @record_data.first[RECORD_DATE_FIELD].to_date
    end

    def delete_records!
      raise(NameError, "batch instantiated without query") if !@deletion_query.present?
      raise(NameError, "batch instantiated without connection") if !@database_connection.present?
      @database_connection.exec_query(@deletion_query)
    end

    def key
      @key ||= ::ActiverecordHoarder::StorageKey.from_date(date, @serializer.extension)
    end

    def present?
      @record_data.present?
    end
  end
end

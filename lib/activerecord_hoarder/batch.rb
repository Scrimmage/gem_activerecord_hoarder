module ::ActiverecordHoarder
  class Batch
    RECORD_DATE_FIELD = "created_at"

    def initialize(record_data, delete_transaction: nil)
      @record_data = record_data
      @serializer = ::ActiverecordHoarder::Serializer
      @delete_transaction = delete_transaction
    end

    def content_string
      @serializer.serialize(@record_data)
    end

    def date
      @date ||= extract_date
    end

    def delete_records!
      raise(NameError, "batch instantiated without delete transaction") if !@delete_transaction.present?
      @delete_transaction.call
    end

    def extract_date
      return nil if !@record_data.first.present?
      @record_data.first[RECORD_DATE_FIELD].to_date
    end

    def key
      @key ||= ::ActiverecordHoarder::StorageKey.from_date(date, @serializer.extension)
    end

    def present?
      @record_data.present?
    end

    def valid?
      return false if !present?
      @record_data.each do |record|
        return false if record['deleted_at'].nil?
      end
      return true
    end
  end
end

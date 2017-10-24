class ::BatchArchiving::BatchArchiver
  RECORD_DATE_FIELD = "created_at"

  def initialize(model_class)
    @record_collector = ::BatchArchiving::RecordCollector.new(model_class)
    @archive_storage = ::BatchArchiving::Storage.new(model_class)
  end

  def archive_batch
    while @record_collector.collect_batch
      @record_collector.with_batch(delete_on_success: true) do |batch_data|
        serialized_batch = ::BatchArchiving::Serializer.create_archive(batch_data)
        key_parts = compose_key(batch_data[0])
        @archive_storage.store_archive(content: serialized_batch, file_type: :json, key_sequence: key_parts)
      end
    end
  end

  private

  def compose_key(record_data)
    date = record_data[RECORD_DATE_FIELD].to_date
    year = date.year.to_s
    month = date.month.to_s
    filename = date.iso8601
    [year, month, filename]
  end
end

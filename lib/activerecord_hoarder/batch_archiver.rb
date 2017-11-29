class ::ActiverecordHoarder::BatchArchiver
  def initialize(model_class, storage = nil)
    @record_collector = ::ActiverecordHoarder::RecordCollector.new(model_class)
    @archive_storage = storage || default_storage_for_records(model_class.table_name)
  end

  def archive_batch
    @record_collector.in_batches(delete_on_success: true) do |batch|
      success = @archive_storage.store_data(batch)
      return if !success
    end
  end

  def default_storage_for_records(table_name)
    ::ActiverecordHoarder::Storage.new(table_name)
  end
end

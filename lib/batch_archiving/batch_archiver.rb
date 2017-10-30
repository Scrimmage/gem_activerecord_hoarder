class ::BatchArchiving::BatchArchiver
  def initialize(model_class, storage = nil)
    @record_collector = ::BatchArchiving::RecordCollector.new(model_class)
    @archive_storage = storage || default_storage_for_records(model_class.table_name)
  end

  def archive_batch
    @record_collector.in_batches(delete_on_success: true) do |batch|
      @archive_storage.store_data(batch)
    end
  end

  def default_storage_for_records(table_name)
    ::BatchArchiving::Storage.new(table_name)
  end
end

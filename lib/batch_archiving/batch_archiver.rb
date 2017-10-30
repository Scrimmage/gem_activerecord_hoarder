class ::BatchArchiving::BatchArchiver
  def initialize(model_class, storage = nil)
    @record_collector = ::BatchArchiving::RecordCollector.new(model_class)
    @archive_storage = storage || default_storage_for_records(model_class.table_name)
  end

  def archive_batch
    while @record_collector.collect_batch
      @record_collector.with_batch(delete_on_success: true) do |batch|
        @archive_storage.store_archive(batch)
      end
    end
  end

  def default_storage_for_records(table_name)
    ::BatchArchiving::Storage.new(table_name)
  end
end

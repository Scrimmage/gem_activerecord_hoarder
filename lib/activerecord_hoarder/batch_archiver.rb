class ::ActiverecordHoarder::BatchArchiver
  def initialize(model_class, storage = nil)
    @batch_collector = ::ActiverecordHoarder::BatchCollector.new(model_class)
    @archive_storage = storage || default_storage_for_records(model_class.table_name)
  end

  def archive_batch
    while @batch_collector.next?
      new_batch = @batch_collector.next_valid
      if new_batch.present?
        success = @archive_storage.store_data(new_batch)
        return if !success
        new_batch.delete_records!
      end
    end
  end

  def default_storage_for_records(table_name)
    ::ActiverecordHoarder::Storage.new(table_name)
  end
end

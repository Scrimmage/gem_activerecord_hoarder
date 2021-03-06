class ::ActiverecordHoarder::BatchArchiver
  def initialize(model_class, storage = nil, start_at_date: nil, max_count: nil)
    @batch_collector = ::ActiverecordHoarder::BatchCollector.new(model_class, lower_limit_override: start_at_date)
    @archive_storage = storage || default_storage_for_records(model_class.table_name)
  end

  def archive_batch
    @batch_collector.each do |new_batch|
      if new_batch.present?
        return if !@archive_storage.store_data(new_batch)
        new_batch.delete_records!
      end
    end
  end

  def default_storage_for_records(table_name)
    ::ActiverecordHoarder::Storage.new(table_name)
  end
end

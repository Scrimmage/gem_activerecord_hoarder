class ::BatchArchiving::BatchArchiver
  def initialize(model_class, storage = nil)
    @record_collector = ::BatchArchiving::RecordCollector.new(model_class)
    if storage == nil
      @archive_storage = ::BatchArchiving::Storage.new(model_class.table_name)
    else
      @archive_storage = storage
    end
  end

  def archive_batch
    while @record_collector.retrieve_batch
      @record_collector.with_batch(delete_on_success: true) do |batch|
        @archive_storage.store_archive(batch)
      end
    end
  end
end

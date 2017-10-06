class ::BatchArchiving::BatchArchiver
  def initialize(model)
    @record_collector = ::BatchArchiving::RecordCollector.new(model)
    @archive_storage = ::BatchArchiving::Storage.new(model)
  end

  def archive_batch
    while @record_collector.retrieve_batch
      @record_collector.with_batch(delete_on_success: true) do |batch_data|
        serialized_batch = ::BatchArchiving::Serializer.create_archive(batch_data)
        @archive_storage.store_archive(batch_data, serialized_batch)
      end
    end
  end
end

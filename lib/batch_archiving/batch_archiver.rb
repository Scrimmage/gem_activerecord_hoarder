require 'batch_archiving/record_collector'
require 'batch_archiving/storage'
require 'batch_archiving/serializer'

class ::BatchArchiving::BatchArchiver
  def initialize(model)
    @record_collector = ::BatchArchiving::RecordCollector.new(model)
    @archive_storage = ::BatchArchiving::Storage.new(model)
  end

  def archive_batch
    while @record_collector.retrieve_batch
      @record_collector.with_batch(delete_on_success: true) do |batch_data|
        serialized_batch = ::BatchArchiving::Serializer.create_archive(batch_data)
        key_parts = compose_key(batch_data[0])
        @archive_storage.store_archive(content: serialized_batch, file_type: :json, key_sequence:key_parts)
      end
    end
  end

  private

  def compose_key(record_data)
    date = record_data["created_at"].to_date
    year = date.year
    month = date.month
    filename = date.iso8601
    [year, month, filename]
  end
end

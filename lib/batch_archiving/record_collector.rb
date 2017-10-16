class ::BatchArchiving::RecordCollector
  attr_reader :relative_limit

  def initialize(model_class)
    @model_class = model_class
  end

  def retrieve_batch
    activate_limit if batch_data_cached? && ! limit_toggled?
    if limit_toggled?
      @current_records = ensuring_new_records do
        retrieve_next_batch
      end
    else
      @current_records = retrieve_first_batch
    end
    batch_data_cached?
  end

  def with_batch(delete_on_success: false)
    raise "no records cached, run `retrieve_batch`" if cached_batch.blank?
    success = yield cached_batch.to_a
    return if ! delete_on_success
    raise "when deleting on success, the block must return a success boolean" if ! success
    destroy_current_records!
  end

  private

  def activate_limit
    @relative_limit = [current_date.end_of_week + 1, archive_timeframe_upper_limit].min
  end

  def archive_timeframe_upper_limit
    Time.now.getutc.to_date
  end

  def batch_data_cached?
    @current_records.try(:any?).present?
  end

  def cached_batch
    @current_records
  end

  def current_date
    @current_records.first["created_at"].to_time(:utc).to_date
  end

  def destroy_current_records!
    @model_class.connection.execute(@batch_query.delete(current_date))
  end

  def ensuring_new_records
    record_batch = yield
    @current_records.values == record_batch.values ? record_batch : []
  end

  def limit_toggled?
    @relative_limit.present?
  end

  def retrieve_first_batch
    @batch_query = ::BatchArchiving::BatchQuery.new(archive_timeframe_upper_limit, @model_class)
    @model_class.connection.execute(@batch_query.fetch)
  end

  def retrieve_next_batch
    @batch_query = ::BatchArchiving::BatchQuery.new(relative_limit, @model_class)
    @model_class.connection.execute(@batch_query.fetch)
  end
end

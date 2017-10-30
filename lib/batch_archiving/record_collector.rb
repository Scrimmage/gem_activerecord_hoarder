class ::BatchArchiving::RecordCollector
  attr_reader :relative_limit

  def initialize(model_class)
    @model_class = model_class
  end

  def in_batches(delete_on_success: false)
    while collect_batch
      success = yield @batch
      return if !success
      next if !delete_on_success
      destroy_current_records!
    end
  end

  private

  def collect_batch
    activate_limit if batch_data_cached? && !limit_toggled?
    if limit_toggled?
      @batch = ensuring_new_records do
        retrieve_next_batch
      end
    else
      @batch = retrieve_first_batch
    end
    batch_data_cached?
  end

  def activate_limit
    @relative_limit = [@batch.date.end_of_week + 1, archive_timeframe_upper_limit].min
  end

  def archive_timeframe_upper_limit
    Time.now.getutc.beginning_of_day
  end

  def batch_data_cached?
    @batch.present?
  end

  def destroy_current_records!
    @model_class.connection.execute(@batch_query.delete(@batch.date))
  end

  def ensuring_new_records
    record_batch = yield
    @batch.date == record_batch.try(:date) ? nil : record_batch
  end

  def limit_toggled?
    @relative_limit.present?
  end

  def retrieve_first_batch
    @batch_query = ::BatchArchiving::BatchQuery.new(archive_timeframe_upper_limit, @model_class)
    batch_data = @model_class.connection.exec_query(@batch_query.fetch)
    ::BatchArchiving::Batch.from_records(batch_data)
  end

  def retrieve_next_batch
    @batch_query = ::BatchArchiving::BatchQuery.new(relative_limit, @model_class)
    batch_data = @model_class.connection.exec_query(@batch_query.fetch)
    ::BatchArchiving::Batch.from_records(batch_data)
  end
end

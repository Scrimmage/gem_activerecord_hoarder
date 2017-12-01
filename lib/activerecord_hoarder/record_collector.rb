class ::ActiverecordHoarder::RecordCollector
  def initialize(model_class, lower_limit_override: nil, max_count: nil)
    @include_lower_limit = true
    @lower_limit = lower_limit_override
    @model_class = model_class
    @max_count = max_count
  end

  def in_batches(delete_on_success: false)
    return if !find_limits
    update_query

    while collect_batch
      batch_is_valid = yield @batch
      update_limits_and_query(batch_is_valid)
      next if !delete_on_success
      destroy_current_records!
    end
  end

  private

  def absolute_upper_limit
    @absolute_upper_limit
  end

  def collect_batch
    @batch = ensuring_new_records do
      retrieve_batch
    end
    batch_data_cached?
  end

  def batch_data_cached?
    @batch.present?
  end

  def destroy_current_records!
    @model_class.connection.exec_query(@batch_query.delete)
  end

  def ensuring_new_records
    record_batch = yield
    return record_batch if @batch.nil?
    return nil if @batch.date == record_batch.try(:date)
    record_batch
  end

  def find_limits
    @lower_limit ||= get_oldest_datetime
    lower_limit.present?
  end

  def get_oldest_datetime
    @model_class
      .unscoped
      .order(::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN)
      .first
      .try(::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN)
  end

  def lower_limit
    @lower_limit
  end

  def upper_limit
    return relative_upper_limit if !absolute_upper_limit
    [relative_upper_limit, absolute_upper_limit].min
  end

  def relative_upper_limit
    lower_limit.end_of_day
  end

  def retrieve_batch
    batch_data = @model_class.connection.exec_query(@batch_query.fetch)
    ::ActiverecordHoarder::Batch.from_records(batch_data)
  end

  def update_absolute_upper_limit(success)
    return if !success
    return if @absolute_upper_limit.present?
    @absolute_upper_limit = @lower_limit.end_of_week
  end

  def update_limits(success)
    update_absolute_upper_limit(success)
    @lower_limit = upper_limit
    @include_lower_limit = false
  end

  def update_limits_and_query(success)
    update_limits(success)
    update_query
  end

  def update_query
    @batch_query = ::ActiverecordHoarder::BatchQuery.new(@model_class, lower_limit, upper_limit, include_lower: @include_lower_limit, include_upper: true)
  end

end

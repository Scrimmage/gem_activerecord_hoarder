class ::ActiverecordHoarder::BatchCollector
  def initialize(model_class, lower_limit_override: nil, max_count: nil)
    @include_lower_limit = true
    @lower_limit = lower_limit_override
    @model_class = model_class
    @max_count = max_count
    find_limits && update_query
  end

  def destroy_current_records_if_valid!
    connection.exec_query(@batch_query.delete) if @batch.valid?
  end

  def next(with_absolute: false)
    @batch = next_batch
    update_limits(with_absolute)
    @batch
  end

  def next?
    next_batch.present?
  end

  def next_valid
    valid_batch = next_batch.valid?
    @batch = valid_batch ? next_batch : ActiverecordHoarder::Batch.new([])
    update_limits(valid_batch)
    @batch
  end

  private

  def absolute_limit_reached?
    [absolute_upper_limit, lower_limit].compact.min == absolute_upper_limit && absolute_upper_limit.present?
  end

  def absolute_upper_limit
    @absolute_upper_limit
  end

  def batch_data_cached?
    @batch.present?
  end

  def collect_batch
    @batch = ensuring_new_records do
      retrieve_batch
    end
  end

  def connection
    @model_class.connection
  end

  def ensuring_new_records
    record_batch = yield
    return record_batch if @batch.nil?
    return nil if @batch.date == record_batch.try(:date)
    record_batch
  end

  def delete_transaction
    Proc.new do
      connection.exec_query(@batch_query.delete)
    end
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

  def next_batch
    @next_batch ||= collect_batch
  end

  def next_batch_data_cached?
    @next_batch.present?
  end

  def upper_limit
    return relative_upper_limit if !absolute_upper_limit
    [relative_upper_limit, absolute_upper_limit].min
  end

  def relative_upper_limit
    lower_limit.end_of_day
  end

  def retrieve_batch
    return ::ActiverecordHoarder::Batch.new([]) if absolute_limit_reached? || !@batch_query.present?
    batch_data = connection.exec_query(@batch_query.fetch)
    ::ActiverecordHoarder::Batch.from_records(batch_data, delete_transaction: delete_transaction)
  end

  def update_absolute_upper_limit
    return if @absolute_upper_limit.present?
    @absolute_upper_limit = @lower_limit.end_of_week
  end

  def update_limits(update_absolute)
    update_absolute_upper_limit if update_absolute
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

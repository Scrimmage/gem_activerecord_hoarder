class ::ActiverecordHoarder::BatchCollector
  def initialize(model_class, lower_limit_override: nil, max_count: nil)
    @count = 0
    @include_lower_limit = true
    @lower_limit = lower_limit_override
    @max_count = max_count
    @model_class = model_class
    find_limits && update_query
  end

  def each(&batch_processing)
    while next?
      yield(send(:next))
    end
  end

  def next
    pop_next_batch
    update
    @batch
  end

  def next?
    return !absolute_limit_reached? if @max_count.nil?
    !absolute_limit_reached? && @count < @max_count
  end

  private

  def absolute_limit_reached?
    lower_limit == absolute_upper_limit || [absolute_upper_limit, lower_limit].compact.min == absolute_upper_limit
  end

  def absolute_upper_limit
    [@absolute_upper_limit, 1.day.ago.utc.end_of_day].compact.min
  end

  def collect_batch
    if absolute_limit_reached? || !@batch_query.present?
      new_batch = ::ActiverecordHoarder::Batch.new([])
    else
      new_batch = ensuring_new_records do
        retrieve_batch
      end
    end
    new_batch
  end

  def ensuring_new_records
    record_batch = yield
    return record_batch if @batch.nil?
    return ::ActiverecordHoarder::Batch.new([]) if @batch.date == record_batch.try(:date)
    record_batch
  end

  def delete_transaction
    delete_query = @batch_query.delete.to_s
    Proc.new {
      @model_class.connection.exec_query(delete_query)
    }
  end

  def find_limits
    @lower_limit ||= get_oldest_datetime
    @lower_limit.present?
  end

  def get_oldest_datetime
    @model_class
      .unscoped
      .order(::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN)
      .first
      .try(::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN)
  end

  def lower_limit
    @lower_limit.utc.beginning_of_day
  end

  def next_batch
    @next_batch ||= collect_batch
  end

  def pop_next_batch
    batch = next_batch
    @next_batch = nil
    @batch = batch.valid? ? batch : ActiverecordHoarder::Batch.new([])
  end

  def relative_upper_limit
    lower_limit + 1.day
  end

  def retrieve_batch
    batch_data = @model_class.connection.exec_query(@batch_query.fetch)
    ::ActiverecordHoarder::Batch.new(batch_data, delete_transaction: delete_transaction)
  end

  def update_absolute_upper_limit
    return if @absolute_upper_limit.present?
    @absolute_upper_limit = lower_limit.end_of_week
  end

  def update
    @count += 1
    update_limits
    update_query
  end

  def update_limits
    update_absolute_upper_limit if @batch.present?
    @lower_limit = relative_upper_limit
    @include_lower_limit = false
  end

  def update_query
    @batch_query = ::ActiverecordHoarder::BatchQuery.new(@model_class, lower_limit, upper_limit, include_lower: @include_lower_limit, include_upper: true)
  end

  def upper_limit
    return relative_upper_limit if !absolute_upper_limit
    [relative_upper_limit, absolute_upper_limit].min
  end
end

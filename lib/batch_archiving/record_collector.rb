class ::BatchArchiving::RecordCollector
  attr_reader :relative_limit

  def initialize(model_class)
    @model = model_class
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
    if delete_on_success
      if success.is_a? TrueClass
        destroy_current_records!
      elsif ! success.is_a? FalseClass
        raise "when deleting on success, the block must return a success boolean"
      end
    end
  end

  private

  def absolute_limit
    Date.today
  end

  def batch_data_cached?
    @current_records.try(:any?).present?
  end

  def cached_batch
    @current_records
  end

  def ensuring_new_records
    record_batch = yield
    @current_records.values == record_batch.values ? record_batch : []
  end

  def limit_toggled?
    @relative_limit.present?
  end

  def activate_limit
    @relative_limit = [@current_records.first["created_at"].to_time(:utc).end_of_week.to_date + 1, absolute_limit].min
  end

  def destroy_current_records!
    @current_records.each do |record_data|
      @model.unscoped.where(id: record_data["id"]).first.really_destroy!
    end
  end

  def retrieve_first_batch
    sql_query = ::BatchArchiving::BatchQuery.new(absolute_limit, @model).to_sql
    ActiveRecord::Base.connection.execute(sql_query)
  end

  def retrieve_next_batch
    sql_query = ::BatchArchiving::BatchQuery.new(relative_limit, @model).to_sql
    ActiveRecord::Base.connection.execute(sql_query)
  end
end

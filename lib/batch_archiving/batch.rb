module ::BatchArchiving::Batch
  RECORD_DATE_FIELD = "created_at"
  REPRESENTATIVE_INDEX = 0

  def initialize(data)
    @data = data
    @serializer = ::BatchArchiving::Serializer
  end

  def date
    @date ||= @data[REPRESENTATIVE_INDEX][RECORD_DATE_FIELD].to_date
  end

  def key
    @key ||= ::BatchArchiving::StorageKey.from_date(date, @serializer.extension)
  end

  def to_s
    @serializer.create_archive(@data)
  end
end

module ActiverecordHoarder::Core
  def self.included(base)
    raise 'created_at accessor needed' if !base.column_names.include?("created_at")
    raise 'deleted_at accessor needed' if !base.column_names.include?("deleted_at")
    base.extend ClassMethods
  end

  module ClassMethods
    def hoard(**kwargs) # :start_at_date, :max_count
      ::ActiverecordHoarder::BatchArchiver.new(self, **kwargs).archive_batch
    end

    def hoard_single(**kwargs)
      kwargs.merge(max_count: 1)
      ::ActiverecordHoarder::BatchArchiver.new(self, **kwargs).archive_batch
    end
  end
end

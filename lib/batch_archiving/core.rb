module BatchArchiving::Core
  def self.included(base)
    raise 'created_at accessor needed' if !base.column_names.include?("created_at")
    raise 'deleted_at accessor needed' if !base.column_names.include?("deleted_at")
    base.extend ClassMethods
  end

  module ClassMethods
    def archive_batch
      ::BatchArchiving::BatchArchiver.new(self).archive_batch
    end
  end
end

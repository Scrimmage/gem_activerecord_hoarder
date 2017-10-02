module BatchArchiving::Core
  def self.included(base)
    raise 'created_at accessor needed' if not base.new.respond_to?(:created_at)
    raise 'deleted_at accessor needed' if not base.new.respond_to?(:deleted_at)
    base.extend ClassMethods
  end

  module ClassMethods
    def archive_batch
    end
  end
end

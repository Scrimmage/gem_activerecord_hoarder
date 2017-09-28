module BatchArchiving::Core
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def archive_batch
    end
  end
end

Dir.glob(File.join("lib","batch_archiving", "*.rb")).each do |file| require File.expand_path(file) end

module BatchArchiving
  def batch_archivable(**options)
    include BatchArchiving::Core
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

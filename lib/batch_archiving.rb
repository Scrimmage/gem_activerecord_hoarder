Dir.glob(File.join("lib","batch_archiving", "*.rb")).each do |file| require file.split("/").drop(1).join("/") end

module BatchArchiving
  def batch_archivable(**options)
    include BatchArchiving::Core
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

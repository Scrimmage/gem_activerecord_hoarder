Dir.glob(File.join("lib","batch_archiving", "*.rb")).each do |file|
  require_path = file.split("/").drop(1).join("/").split(".")[0]
  require require_path
end

module BatchArchiving
  def batch_archivable(**options)
    include BatchArchiving::Core
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

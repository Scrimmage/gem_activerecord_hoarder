Dir.glob(File.join("lib","batch_archiving", "*.rb")).each do |file|
  file_path = file.split("/").drop(1).join("/")
  raise "requiring #{file_path}"
  require file_path
end

module BatchArchiving
  def batch_archivable(**options)
    include BatchArchiving::Core
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

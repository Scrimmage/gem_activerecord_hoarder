require 'batch_archiving/aws_s3_storage'
require 'batch_archiving/batch_archiver'
require 'batch_archiving/core'
require 'batch_archiving/record_collector'
require 'batch_archiving/record_query'
require 'batch_archiving/serializer'
require 'batch_archiving/storage'
require 'batch_archiving/storage_error'
require 'batch_archiving/storages'

module BatchArchiving
  def batch_archivable(**options)
    include BatchArchiving::Core
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

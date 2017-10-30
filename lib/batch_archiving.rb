require 'batch_archiving/aws_s3_storage'
require 'batch_archiving/batch'
require 'batch_archiving/batch_archiver'
require 'batch_archiving/core'
require 'batch_archiving/record_collector'
require 'batch_archiving/record_query'
require 'batch_archiving/restore'
require 'batch_archiving/serializer'
require 'batch_archiving/storage'
require 'batch_archiving/storage_error'
require 'batch_archiving/storage_key'
require 'batch_archiving/storages'

module BatchArchiving
  def batch_archivable
    include BatchArchiving::Core
    include BatchArchiving::Restore
  end
end

::ActiveRecord::Base.send :extend, BatchArchiving

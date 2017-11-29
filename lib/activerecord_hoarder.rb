require 'activerecord_hoarder/aws_s3_storage'
require 'activerecord_hoarder/batch'
require 'activerecord_hoarder/batch_archiver'
require 'activerecord_hoarder/batch_query'
require 'activerecord_hoarder/core'
require 'activerecord_hoarder/record_collector'
require 'activerecord_hoarder/restore'
require 'activerecord_hoarder/serializer'
require 'activerecord_hoarder/storage'
require 'activerecord_hoarder/storage_error'
require 'activerecord_hoarder/storage_key'
require 'activerecord_hoarder/storages'

module ActiverecordHoarder
  def acts_as_hoarder
    include ActiverecordHoarder::Core
    include ActiverecordHoarder::Restore
  end
end

::ActiveRecord::Base.send :extend, ActiverecordHoarder

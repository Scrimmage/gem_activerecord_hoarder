require "bundler/setup"
require "active_record"
require "aws-sdk-s3"

require "batch_archiving"

require "factory_girl_rails"
require "pp"
require "timecop"

Dir.glob("spec/support/*.rb").each do |file| require File.expand_path(file) end

class ExampleArchivable < ActiveRecord::Base
  batch_archivable
end

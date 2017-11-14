require "bundler/setup"
require "active_record"
require "aws-sdk-s3"

require "activerecord_hoarder"

require "factory_girl_rails"
require "pp"
require "timecop"

Dir.glob("spec/support/*.rb").each do |file| require File.expand_path(file) end

class ExampleHoarder < ActiveRecord::Base
  acts_as_hoarder
end

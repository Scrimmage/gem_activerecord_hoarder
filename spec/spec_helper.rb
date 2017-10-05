require "bundler/setup"
require "active_record"
require "paranoia"
require "batch_archiving"
require "factory_girl_rails"
require "pp"
require "timecop"

Dir.glob("spec/support/*.rb").each do |file| require File.expand_path(file) end

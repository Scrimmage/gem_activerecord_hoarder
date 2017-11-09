
RSpec.configure do |config|
  config.after(:each) do
    ActiverecordHoarder.send(:remove_const, 'Storage')
    load 'lib/activerecord_hoarder/storage.rb'
  end
end

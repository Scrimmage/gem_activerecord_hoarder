
RSpec.configure do |config|
  config.after(:each) do
    BatchArchiving.send(:remove_const, 'Storage')
    load 'lib/batch_archiving/storage.rb'
  end
end

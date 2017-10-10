::BatchArchiving::StorageOptions = YAML.load_file("config/batch_archiving_rspec.yml")

RSpec.configure do |config|
  config.after(:each) do
    BatchArchiving.send(:remove_const, 'Storage')
    load 'lib/batch_archiving/storage.rb'
  end
end

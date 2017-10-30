require 'spec_helper'

DATA_TEMPLATE = "data for key %{key}"

RSpec.describe ::BatchArchiving::AwsS3 do
  describe ".fetch_data" do
    let(:date_data) { DATA_TEMPLATE % { key: full_key } }
    let(:full_key) { File.join(table_name, key_string) }
    let(:key) { double(content_string: key_string) }
    let(:key_string) { "key" }
    let(:storage) { ::BatchArchiving::AwsS3.new(table_name, storage_options) }
    let(:storage_options) { {} }
    let(:table_name) { "records" }

    before do
      allow(storage).to receive(:s3_client).and_return(Aws::S3::Client.new(stub_responses: true))
      allow_any_instance_of(Aws::S3::Client).to receive(:get_object) do |object, args|
        double(body: DATA_TEMPLATE % { key: args[:key] })
      end
    end

    it "returns the archive entry for given date" do
      expect(storage.fetch_data(key)).to eq(date_data)
    end
  end
end

require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::Storage do
  let(:stub_model) { double }

  before do
    allow(stub_model).to receive(:table_name)
  end

  describe "new" do
    let(:storage) { ::ActiverecordHoarder::Storage.new(stub_model) }

    context "not configured" do
      it "fails and complains about configuration" do
        expect{ ::ActiverecordHoarder::Storage.new(stub_model) }.to raise_error(::ActiverecordHoarder::StorageError)
      end
    end

    context "aws_s3" do
      before do
        ::ActiverecordHoarder::Storage.configure(storage: :aws_s3, storage_options: {})
      end

      it "returns an aws storage" do
        expect(storage.class).to be(::ActiverecordHoarder::AwsS3)
      end
    end
  end
end

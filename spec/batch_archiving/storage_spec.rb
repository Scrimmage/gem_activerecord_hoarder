require 'spec_helper'

RSpec.describe ::BatchArchiving::Storage do
  describe "new" do
    let(:storage) { ::BatchArchiving::Storage.new(:Model) }

    context "not configured" do
      it "fails and complains about configuration" do
        expect{ ::BatchArchiving::Storage.new(:Model) }.to raise_error(::BatchArchiving::StorageError)
      end
    end

    context "aws_s3" do
      before do
        ::BatchArchiving::Storage.configure(storage: :aws_s3, storage_options: {})
      end

      it "returns an aws storage" do
        expect(storage.class).to be(::BatchArchiving::AwsS3)
      end
    end
  end
end

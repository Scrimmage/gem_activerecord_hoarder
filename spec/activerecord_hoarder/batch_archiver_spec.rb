require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::BatchArchiver do
  subject { ::ActiverecordHoarder::BatchArchiver.new(ExampleHoarder, storage: storage) }
  let(:storage) { double("storage") }

  it "creates instance that can archive_batch" do
    expect(subject).to respond_to(:archive_batch)
  end

  describe "archive_batch" do
    let(:batch_collector) { ::ActiverecordHoarder::BatchCollector }
    let(:batch1) { double("batch1") }
    let(:batch2_invalid) { double("batch2") }
    let(:batch3) { double("batch3") }

    after do
      subject.archive_batch
    end

    it "loops through batch_collector generated batches" do
      expect(batch_collector).to receive(:next?).exactly(3).times
    end

    describe "batch processing" do
      it "receives the new batch" do
        expect(batch_collector).to receive(:next).and_return(batch1)
        expect(batch_collector).to receive(:next).and_return(batch2_invalid)
        expect(batch_collector).to receive(:next).and_return(batch3)
      end

      it "validates the batch" do
        expect(batch1).to receive(:valid?).and_return(true)
        expect(batch2_invalid).to receive(:valid?).and_return(false)
        expect(batch3).to receive(:valid?).and_return(true)
      end

      it "stores the valid batches" do
        expect(storage).to receive(:store_data).with(batch1)
        expect(storage).to receive(:store_data).with(batch3)
      end

      it "breaks the loop if storage is unsuccessful" do
        expect(storage).to receive(:store_data).with(batch3).and_return(false)
        expect(subject).not_to receive(:next?)
      end
    end
  end
end

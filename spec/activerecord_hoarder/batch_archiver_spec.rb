require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::BatchArchiver do
  subject { ::ActiverecordHoarder::BatchArchiver.new(ExampleHoarder, storage) }
  let(:batch_collector) { ::ActiverecordHoarder::BatchCollector.new(ExampleHoarder) }
  let(:batch_instance) { double("batch_instance", delete_records!: nil) }
  let(:storage) { double("storage") }

  before do
    allow(::ActiverecordHoarder::BatchCollector).to receive(:new).and_return(batch_collector)
    allow(storage).to receive(:store_data).and_return(true)
    allow(batch_collector).to receive(:next).and_return(batch_instance)
    allow(batch_collector).to receive(:next?).and_return(true)
  end

  it "creates instance that can archive_batch" do
    expect(subject).to respond_to(:archive_batch)
  end

  describe "archive_batch" do
    def batch_double(double_name, present = true)
      double(double_name, present?: present, delete_records!: nil)
    end

    let(:batch1) { batch_double("batch1") }
    let(:batch2) { batch_double("batch2", false) }
    let(:batch3) { batch_double("batch3") }

    after do
      subject.archive_batch
    end

    it "loops through batch_collector generated batches" do
      expect(batch_collector).to receive(:next?).and_return(true, true, false)
      expect(batch_collector).not_to receive(:next?)
    end

    describe "batch processing" do
      before do
        allow(batch_collector).to receive(:next?).and_return(true, true, true, false)
        allow(batch_collector).to receive(:next).and_return(batch1, batch2, batch3)
      end

      it "receives the new batch" do
        expect(batch_collector).to receive(:next).and_return(batch1)
        expect(batch_collector).to receive(:next).and_return(batch2)
        expect(batch_collector).to receive(:next).and_return(batch3)
      end

      it "stores the non_empty batches" do
        expect(storage).to receive(:store_data).with(batch1)
        expect(storage).to receive(:store_data).with(batch3)
      end

      it "deletes the non_empty records" do
        expect(batch1).to receive(:delete_records!)
        expect(batch2).not_to receive(:delete_records!)
        expect(batch3).to receive(:delete_records!)
      end

      it "breaks the loop if storage is unsuccessful" do
        expect(batch_collector).to receive(:next?).ordered
        expect(storage).to receive(:store_data).with(batch1).and_return(true).ordered
        expect(batch1).to receive(:delete_records!).ordered
        expect(batch_collector).to receive(:next?).ordered
        expect(batch_collector).to receive(:next?).ordered
        expect(storage).to receive(:store_data).with(batch3).and_return(false).ordered
        expect(batch3).not_to receive(:delete_records!).ordered
        expect(batch_collector).not_to receive(:next?).ordered
      end
    end
  end
end

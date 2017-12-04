require "spec_helper"

RSpec.describe ::ActiverecordHoarder::Batch do
  subject { described_class.new(record_data) }
  let(:record_data) { [] }

  describe "present?" do
    before do
      expect(subject).to receive(:present?).and_call_original
    end

    context "record_data exists" do
      let(:record_data) { double("record_data", present?: true) }

      it "returns true" do
        expect(subject.present?).to be(true)
      end
    end

    context "record_data does not exist" do
      it "returns false" do
        expect(subject.present?).to be(false)
      end
    end
  end
end

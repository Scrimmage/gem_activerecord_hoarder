require "spec_helper"

RSpec.describe ::ActiverecordHoarder::Batch do
  subject { described_class.new(record_data, delete_transaction: delete_transaction) }
  let(:delete_transaction) { double("delete_transaction") }
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

  describe "delete_records!" do
    it "is implemented" do
      expect(described_class.instance_methods).to include(:delete_records!)
    end

    describe "function" do
      context "transaction missing" do
        let(:delete_transaction) { nil }

        it "raises an error" do
          expect{ subject.delete_records! }.to raise_error(NameError, "batch instantiated without delete transaction")
        end
      end

      context "requirements met" do
        it "executes query against connection" do
          expect(delete_transaction).to receive(:call)
          subject.delete_records!
        end
      end
    end
  end
end

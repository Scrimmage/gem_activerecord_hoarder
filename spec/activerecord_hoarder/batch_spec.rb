require "spec_helper"

RSpec.describe ::ActiverecordHoarder::Batch do
  subject { described_class.new(record_data, database_connection: connection, deletion_query: deletion_query) }
  let(:connection) { double("connection") }
  let(:deletion_query) { double("deletion_query") }
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
      context "query missing" do
        let(:deletion_query) { nil }

        it "raises an error" do
          expect{ subject.delete_records! }.to raise_error(NameError, "batch instantiated without query")
        end
      end

      context "connection missing" do
        let(:connection) { nil }

        it "raises an error" do
          expect{ subject.delete_records! }.to raise_error(NameError, "batch instantiated without connection")
        end
      end

      context "requirements met" do
        it "executes query against connection" do
          expect(connection).to receive(:exec_query).with(deletion_query)
          subject.delete_records!
        end
      end
    end
  end
end

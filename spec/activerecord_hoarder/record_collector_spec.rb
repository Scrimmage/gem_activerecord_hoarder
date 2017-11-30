require "spec_helper"

RSpec.describe ::ActiverecordHoarder::RecordCollector do
  subject { described_class.new(hoarder_class, lower_limit_override: lower_limit_override, max_count: max_count) }
  let(:hoarder_class) { double }
  let(:lower_limit_override) { nil }
  let(:max_count) { nil }

  describe "public" do
    describe "in_batches" do
      let(:delete_on_success) { false }
      let(:limit_success) { true }

      before do
        allow(subject).to receive(:find_limits).and_return(limit_success)
        allow(subject).to receive(:collect_batch).and_return(true, false)
      end

      after do
        subject.in_batches(delete_on_success: delete_on_success) {}
      end

      context "limits not found" do
        let(:limit_success) { false }

        it "exits early" do
          expect(subject).not_to receive(:collect_batch)
        end
      end

      context "limits found" do
        let(:batch_success) { [true, true, false] }

        before do
          allow(subject).to receive(:collect_batch).and_return(*batch_success)
        end

        it "yields batches until it runs out" do
          expect(subject).to receive(:collect_batch).exactly(batch_success.length).times
        end

        context "delete on success" do
          let(:delete_on_success) { true }

          it "calls destroy_current_records!" do
            expect(subject).to receive(:destroy_current_records!).twice
          end
        end

        context "does not delete on success" do
          it "does not call destroy_current_records!" do
            expect(subject).not_to receive(:destroy_current_records!)
          end
        end
      end
    end
  end

  describe "private" do
    describe "collect_batch" do
      let(:ensured_batch) { double("retrieved_batch") }

      before do
        allow(subject).to receive(:ensuring_new_records).and_return(ensured_batch)
        allow(subject).to receive(:retrieve_batch)
        allow(subject).to receive(:update_limits)
      end

      context "record not new" do
        let(:ensured_batch) { nil }

        it "sets @batch to be 'nil' and returns false" do
          expect(subject.send(:collect_batch)).to be(false)
          expect(subject.instance_variable_get(:@batch)).to eq(nil)
        end
      end

      context "record new" do
        it "sets @batch from records and returns true" do
          expect(subject.send(:collect_batch)).to be(true)
          expect(subject.instance_variable_get(:@batch)).to eq(ensured_batch)
        end
      end

      it "updates the limits" do
        expect(subject).to receive(:update_limits)
        subject.send(:collect_batch)
      end
    end

    describe "destroy_current_records!" do
      let(:batch_query) { double("batch_query", delete: delete_query) }
      let(:connection) { double("connection", execute: nil) }
      let(:delete_query) { "delete_query" }

      before do
        allow(hoarder_class).to receive(:connection).and_return(connection)
        subject.instance_variable_set(:@batch_query, batch_query)
      end

      it "uses batch_query to delete records" do
        expect(batch_query).to receive(:delete)
        expect(connection).to receive(:execute).with(delete_query)
        subject.send(:destroy_current_records!)
      end
    end

    describe "ensuring_new_records" do
      let(:new_batch) { double("new batch", date: new_date) }
      let(:new_date) { double("new date") }
      let(:old_batch) { double("different batch", date: date_reference) }
      let(:date_reference) { double("different date") }

      before do
        subject.instance_variable_set(:@batch, old_batch)
      end

      context "batch date same as previous" do
        let(:date_reference) { new_date }

        it "doesn't return new batch" do
          expect(subject.send(:ensuring_new_records) { new_batch } ).to eq(nil)
        end
      end

      context "batch different from previous" do
        it "returns new batch" do
          expect(subject.send(:ensuring_new_records) { new_batch } ).to eq(new_batch)
        end
      end

      context "previous batch not set" do
        let(:old_batch) { nil }

        it "returns new batch" do
          expect(subject.send(:ensuring_new_records) { new_batch } ).to eq(new_batch)
        end
      end
    end

    describe "find_limits" do
      let(:limit_from_records) { nil }
      let(:lower_limit_override) { nil }

      before do
        allow(subject).to receive(:get_oldest_datetime).and_return(limit_from_records)
        subject.instance_variable_set(:@lower_limit_override, lower_limit_override)
      end

      context "with lower_limit_override" do
        let(:lower_limit_override) { double("lower_limit_override") }

        it "sets outer_limit_lower to lower_limit_override and returns true" do
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_get(:@outer_limit_lower)).not_to eq(nil)
          expect(subject.instance_variable_get(:@outer_limit_lower)).to eq(lower_limit_override)
        end
      end

      context "without lower_limit_override" do
        let(:limit_from_records) { double("limit_from_records") }

        it "sets outer_limit_lower from records and returns true" do
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_get(:@outer_limit_lower)).not_to eq(nil)
          expect(subject.instance_variable_get(:@outer_limit_lower)).to eq(limit_from_records)
        end
      end

      context "without any source for limits" do
        it "does not set outer_limit_lower and returns false" do
          expect(subject.send(:find_limits)).to eq(false)
          expect(subject.instance_variable_get(:@outer_limit_lower)).to eq(nil)
        end
      end
    end

  end
end

require "spec_helper"

RSpec.describe ::ActiverecordHoarder::RecordCollector do
  subject { described_class.new(hoarder_class, lower_limit_override: lower_limit_override, max_count: max_count) }
  let(:batch_query) { double("batch_query", delete: delete_query, fetch: fetch_query) }
  let(:delete_query) { "delete_query" }
  let(:fetch_query) { "fetch_query" }
  let(:hoarder_class) { double("hoarder_class", connection: hoarder_connection) }
  let(:hoarder_connection) { double("hoarder_connection", exec_quer: nil) }
  let(:lower_limit_override) { double("lower_limit_override", end_of_day: upper_limit_from_override) }
  let(:max_count) { nil }
  let(:upper_limit_from_override) { double("upper_limit_from_override") }

  before do
    subject.instance_variable_set(:@batch_query, batch_query)
  end

  describe "accuracy" do
    it "handles time accuracy gracefully"
  end

  describe "public" do
    describe "in_batches" do
      let(:delete_on_success) { false }
      let(:limit_success) { true }

      before do
        allow(subject).to receive(:collect_batch).and_return(true, false)
        allow(subject).to receive(:destroy_current_records!)
        allow(subject).to receive(:find_limits).and_return(limit_success)
        allow(subject).to receive(:update_limits_and_query)
        allow(subject).to receive(:update_query)
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

        it "creates a query and updates before every new batch" do
          expect(subject).to receive(:update_query).ordered
          expect(subject).to receive(:collect_batch).ordered
          expect(subject).to receive(:update_limits_and_query).ordered
          expect(subject).to receive(:collect_batch).ordered
          expect(subject).to receive(:update_limits_and_query).ordered
        end

        it "yields batches until it runs out" do
          expect(subject).to receive(:collect_batch).exactly(batch_success.length).times
        end

        context "deleting records" do
          let(:delete_on_success) { true }

          it "calls destroy_current_records!" do
            expect(subject).to receive(:destroy_current_records!).twice
          end
        end

        context "not deleting records" do
          it "does not call destroy_current_records!" do
            expect(subject).not_to receive(:destroy_current_records!)
          end
        end
      end
    end
  end

  describe "private" do
    describe "absolute_upper_limit" do
      let(:absolute_upper_limit) { double("absolute_upper_limit") }

      before do
        subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit)
      end

      it "returns stored upper limit" do
        expect(subject.send(:absolute_upper_limit)).to eq(absolute_upper_limit)
      end
    end

    describe "collect_batch" do
      let(:ensured_batch) { double("retrieved_batch") }

      before do
        allow(subject).to receive(:ensuring_new_records).and_return(ensured_batch)
        allow(subject).to receive(:retrieve_batch)
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
    end

    describe "batch_data_cached?" do
      context "batch cached" do
        let(:batch) { double("batch") }

        before do
          subject.instance_variable_set(:@batch, batch)
          expect(subject.instance_variable_get(:@batch)).not_to be(nil)
        end

        it "returns true" do
          expect(subject.send(:batch_data_cached?)).to be(true)
        end
      end

      context "batch not cached" do
        before do
          expect(subject.instance_variable_get(:@batch)).to be(nil)
        end

        it "returns false" do
          expect(subject.send(:batch_data_cached?)).to be(false)
        end
      end
    end

    describe "destroy_current_records!" do
      before do
        subject.instance_variable_set(:@batch_query, batch_query)
      end

      it "uses batch_query to delete records" do
        expect(batch_query).to receive(:delete)
        expect(hoarder_connection).to receive(:exec_query).with(delete_query)
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

      context "with lower limit is overridden" do
        let(:lower_limit_override) { double("lower_limit_override") }

        before do
          subject.instance_variable_set(:@lower_limit, lower_limit_override)
        end

        it "does not modify lower limit and returns true" do
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(true)
          expect(subject.instance_variable_get(:@lower_limit)).not_to eq(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(lower_limit_override)
        end
      end

      context "lower limit is not overridden" do
        let(:limit_from_records) { double("limit_from_records") }

        it "sets inner_lower_limit from records and returns true" do
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(true)
          expect(subject.instance_variable_get(:@lower_limit)).not_to eq(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(limit_from_records)
        end
      end

      context "without any source for limits" do
        it "does not set inner_lower_limit and returns false" do
          expect(subject.send(:find_limits)).to eq(false)
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(true)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(nil)
        end
      end
    end

    describe "get_oldest_datetime" do
      let(:hoarder_class) { ExampleHoarder }
      let(:raw_minimum) { creation_times.min.utc }
      let(:raw_result) { subject.send(:get_oldest_datetime) }
      let(:rounded_minimum) {  raw_minimum - raw_minimum.to_i % 1.second }
      let(:rounded_result) { raw_result - raw_result.to_i % 1.second }

      context "records exist" do
        let(:creation_times) { [5.days.ago, 4.days.ago, 3.days.ago] }

        before do
          create(:example_hoarder, deleted: false, created_at: creation_times[0])
          create(:example_hoarder, deleted: true, created_at: creation_times[1])
          create(:example_hoarder, deleted: false, created_at: creation_times[2])
        end

        it "returns oldest date" do
          expect(rounded_result).to eq(rounded_minimum)
        end
      end

      context "no records exist" do
        it "returns nil" do
          expect(subject.send(:get_oldest_datetime)).to be(nil)
        end
      end
    end

    describe "lower_limit" do
      let(:lower_limit_override) { double("lower_limit") }

      it "returns lower_limit" do
        expect(subject.send(:lower_limit)).to eq(lower_limit_override)
      end
    end

    describe "upper_limit" do
      before do
        allow(subject).to receive(:relative_upper_limit).and_return(relative_upper_limit)
        allow(subject).to receive(:absolute_upper_limit).and_return(absolute_upper_limit)
      end

      context "absolute_upper_limit yet unknown" do
        let(:relative_upper_limit) { double("relative_upper_limit") }
        let(:absolute_upper_limit) { nil }

        it "returns relative_upper_limit" do
          expect(subject.send(:upper_limit)).to eq(relative_upper_limit)
        end
      end

      context "absolute_upper_limit known" do
        let(:absolute_upper_limit) { 2.days.ago }

        context "relative_upper_limit less than absolute_upper_limit" do
          let(:relative_upper_limit) { 3.days.ago }

          it "returns relative_upper_limit" do
            expect(subject.send(:upper_limit)).to eq(relative_upper_limit)
          end
        end

        context "relative_upper_limit more than absolute_upper_limit" do
          let(:relative_upper_limit) { 1.day.ago }

          it "returns absolute_upper_limit" do
            expect(subject.send(:upper_limit)).to eq(absolute_upper_limit)
          end
        end
      end
    end

    describe "relative_upper_limit" do
      let(:lower_limit) { 3.days.ago }
      let(:relative_upper_limit) { lower_limit.end_of_day }

      before do
        subject.instance_variable_set(:@lower_limit, lower_limit)
      end

      it "returns upper limit in respect to lower limit" do
        expect(subject.send(:relative_upper_limit)).to eq(relative_upper_limit)
      end
    end

    describe "retrieve_batch" do
      let(:batch_data) { double("batch_data") }
      let(:batch_instance) { double("batch_instance") }

      before do
        allow(hoarder_connection).to receive(:exec_query).and_return(batch_data)
        allow(::ActiverecordHoarder::Batch).to receive(:from_records).and_return(batch_instance)
      end

      it "uses batch_query to retrieve batch_data" do
        expect(batch_query).to receive(:fetch)
        expect(hoarder_connection).to receive(:exec_query).with(fetch_query)
        subject.send(:retrieve_batch)
      end

      it "uses retrieved batch_data to return Batch instance" do
        expect(::ActiverecordHoarder::Batch).to receive(:from_records).with(batch_data)
        expect(subject.send(:retrieve_batch)).to eq(batch_instance)
      end
    end

    describe "update_absolute_upper_limit" do
      after do
        subject.send(:update_absolute_upper_limit, success)
        expect(subject.instance_variable_get(:@absolute_upper_limit)).to eq(absolute_upper_limit_expectation)
      end

      context "success = false" do
        let(:success) { false }
        let(:absolute_upper_limit_expectation) { nil }

        it "returns and does nothing" do
        end
      end

      context "success = true" do
        let(:success) {true}

        before do
          subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit_before)
        end

        context "absolute_upper_limit already set" do
          let(:absolute_upper_limit_before) { double("absolute_upper_limit") }
          let(:absolute_upper_limit_expectation) { absolute_upper_limit_before }

          it "does not change absolute_upper_limit" do
          end
        end

        context "absolute_upper_limit not yet set" do
          let(:absolute_upper_limit_before) { nil }
          let(:absolute_upper_limit_expectation) { absolute_upper_limit_new }
          let(:absolute_upper_limit_new) { double("absolute_upper_limit_new") }
          let(:lower_limit_override) { double("lower_limit", end_of_week: absolute_upper_limit_new) }

          it "sets absolute_upper_limit" do
          end
        end
      end
    end

    describe "update_limits" do
      let(:previous_upper_limit) { double("previous_upper_limit") }
      let(:success) { double("success") }

      before do
        allow(subject).to receive(:update_absolute_upper_limit)
        allow(subject).to receive(:upper_limit).and_return(previous_upper_limit)
      end

      it "updates absolute_upper_limit before using upper limit" do
        expect(subject).to receive(:update_absolute_upper_limit).with(success).ordered
        expect(subject).to receive(:upper_limit).ordered
        subject.send(:update_limits, success)
      end

      it "moves to the next interval starting at last outer_upper_limit" do
        subject.send(:update_limits, success)
        expect(previous_upper_limit).not_to be(nil)
        expect(subject.instance_variable_get(:@lower_limit)).to eq(previous_upper_limit)
      end

      it "sets limit inclusion" do
        expect(subject.instance_variable_get(:@include_lower_limit)).to be(true)
        subject.send(:update_limits, success)
        expect(subject.instance_variable_get(:@include_lower_limit)).to be(false)
      end
    end

    describe "update_limits_and_query" do
      it "updates limits first, then update query" do
        expect(subject).to receive(:update_limits).ordered
        expect(subject).to receive(:update_query).ordered
        subject.send(:update_limits_and_query,nil)
      end
    end

    describe "update_query" do
      let(:old_query) { double("old query") }
      let(:new_query) { double("new query") }

      before do
        allow(::ActiverecordHoarder::BatchQuery).to receive(:new).and_return(new_query)
        subject.instance_variable_set(:@batch_query, old_query)
      end

      it "reconstructs query" do
        expect(::ActiverecordHoarder::BatchQuery).to receive(:new).with(hoarder_class, lower_limit_override, upper_limit_from_override, {include_lower: true, include_upper: true})
        subject.send(:update_query)
        expect(subject.instance_variable_get(:@batch_query)).to be(new_query)
      end
    end
  end
end

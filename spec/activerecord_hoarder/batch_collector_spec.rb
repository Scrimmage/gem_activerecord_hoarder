require "spec_helper"

RSpec.describe ::ActiverecordHoarder::BatchCollector do
  subject { described_class.new(hoarder_class, lower_limit_override: lower_limit_override, max_count: max_count) }
  let(:batch_instance) { double("batch_instance", present?: true) }
  let(:batch_query) { double("batch_query", delete: delete_query, fetch: fetch_query) }
  let(:delete_query) { "delete_query" }
  let(:empty_batch) { double("empty_batch", present?: false) }
  let(:fetch_query) { "fetch_query" }
  let(:hoarder_class) { double("hoarder_class", connection: hoarder_connection) }
  let(:hoarder_connection) { double("hoarder_connection", exec_query: nil) }
  let(:lower_limit_override) { double("lower_limit_override", end_of_day: upper_limit_from_override) }
  let(:max_count) { nil }
  let(:upper_limit_from_override) { double("upper_limit_from_override") }

  before do
    allow_any_instance_of(::ActiverecordHoarder::BatchCollector).to receive(:find_limits)
    allow_any_instance_of(::ActiverecordHoarder::BatchCollector).to receive(:update_query)
    subject.instance_variable_set(:@batch_query, batch_query)
    allow(::ActiverecordHoarder::Batch).to receive(:from_records).and_return(batch_instance)
    allow(::ActiverecordHoarder::Batch).to receive(:new).and_return(empty_batch)
  end

  describe "accuracy" do
    it "handles time accuracy gracefully"
  end

  describe "public" do
    let(:first_lower_limit) { double("first_lower_limit") }
    let(:first_upper_limit) { double("first_upper_limit") }

    describe "(removed) in_batches" do
      it "is removed" do
        expect(subject).not_to respond_to(:in_batches)
      end
    end

    describe "destroy_current_records_if_valid!" do
      let(:current_batch) { double("validated batch", valid?: batch_valid) }

      before do
        subject.instance_variable_set(:@batch_query, batch_query)
        subject.instance_variable_set(:@batch, current_batch)
      end

      after do
        subject.send(:destroy_current_records_if_valid!)
      end

      context "current batch was valid" do
        let(:batch_valid) { true }

        it "uses batch_query to delete records" do
          expect(batch_query).to receive(:delete)
          expect(hoarder_connection).to receive(:exec_query).with(delete_query)
        end
      end

      context "current batch is not valid" do
        let(:batch_valid) { false }

        it "will not delete the records" do
          expect(hoarder_connection).not_to receive(:exec_query)
        end
      end
    end

    describe "next" do
      before do
        expect(subject).to receive(:next).and_call_original
        allow(subject).to receive(:next_batch).and_return(batch_instance)
        allow(subject).to receive(:upper_limit).and_return(first_upper_limit)
      end

      it "uses retreival functionality implemented by next_batch" do
        expect(subject).to receive(:next_batch)
        subject.send(:next)
      end

      it "caches the batch" do
        expect(subject.instance_variable_get(:@batch)).not_to be(batch_instance)
        subject.send(:next)
        expect(subject.instance_variable_get(:@batch)).to be(batch_instance)
      end

      it "returns next batch" do
        expect(subject.next).to eq(batch_instance)
      end

      it "updates position" do
        expect(subject.send(:lower_limit)).to eq(lower_limit_override)
        subject.next
        expect(subject.send(:lower_limit)).to eq(first_upper_limit)
      end
    end

    describe "next?" do
      let(:next_batch) { batch_instance }

      before do
        allow(subject).to receive(:next_batch).and_return(next_batch)
      end

      it "is implemented" do
        expect(subject).to respond_to(:next?)
      end

      it "uses next_batch functionality and checks result presence" do
        expect(batch_instance).to receive(:present?)
        subject.next?
      end

      context "there is a next batch" do
        it "returns true" do
          expect(subject.next?).to be(true)
        end
      end

      context "there is no next batch" do
        let(:next_batch) { empty_batch }

        it "returns false" do
          expect(subject.next?).to be(false)
        end
      end
    end

    describe "next_valid" do
      before do
        allow(subject).to receive(:next_batch).and_return(batch_instance)
        allow(subject).to receive(:upper_limit).and_return(first_upper_limit)
      end

      context "invalid batch next" do
        let(:batch_instance) { double("invalid batch", valid?: false) }

        it "returns empty batch" do
          expect(subject.next_valid).to eq(empty_batch)
        end

        it "caches empty batch" do
          expect(subject.instance_variable_get(:@batch)).not_to eq(empty_batch)
          subject.next_valid
          expect(subject.instance_variable_get(:@batch)).to eq(empty_batch)
        end

        it "does not update the absolute limit" do
          expect(subject).not_to receive(:update_absolute_upper_limit)
        end
      end

      context "valid batch next" do
        let(:batch_instance) { double("valid batch", valid?: true) }

        before do
          allow(subject).to receive(:update_absolute_upper_limit)
        end

        it "returns batch" do
          expect(subject.next_valid).to eq(batch_instance)
        end

        it "caches batch" do
          expect(subject.instance_variable_get(:@batch)).not_to eq(batch_instance)
          subject.next_valid
          expect(subject.instance_variable_get(:@batch)).to eq(batch_instance)
        end

        it "updates the absolute limit" do
          expect(subject).to receive(:update_absolute_upper_limit)
          subject.next_valid
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

    describe "absolute_limit_reached" do
      let(:lower_limit_override) { 2 }
      let(:absolute_upper_limit) { 3 }

      before do
        subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit)
      end

      it "is implemented" do
        expect(subject.private_methods).to include(:absolute_limit_reached?)
      end

      context "lower_limit is below absolute_upper_limit" do
        it "returns false" do
          expect(subject.send(:absolute_limit_reached?)).to be(false)
        end
      end

      context "lower_limit is not below absolute_upper_limit" do
        let(:absolute_upper_limit) { 1 }

        it "returns true" do
          expect(subject.send(:absolute_limit_reached?)).to be(true)
        end
      end
    end

    describe "collect_batch" do
      let(:cached_batch) { double("cached_batch", date: date1 ) }
      let(:ensured_batch) { double("retrieved_batch", date: date2) }
      let(:date1) { double("earlier date") }
      let(:date2) { double("new date") }

      before do
        allow(subject).to receive(:retrieve_batch).and_return(ensured_batch)
        subject.instance_variable_set(:@batch, cached_batch)
      end

      context "record not new" do
        let(:date2) { date1 }

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

    describe "connection" do
      it "returns model database connection" do
        expect(subject.send(:connection)).to eq(subject.instance_variable_get(:@model_class).connection)
      end
    end

    describe "batch_data_cached?" do
      context "batch cached" do
        before do
          subject.instance_variable_set(:@batch, batch_instance)
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
        allow(subject).to receive(:find_limits).and_call_original
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
      let(:expected) { creation_times.min.utc.iso8601(0) }
      let(:result) { subject.send(:get_oldest_datetime).iso8601(0) }

      context "records exist" do
        let(:creation_times) { [5.days.ago, 4.days.ago, 3.days.ago] }

        before do
          create(:example_hoarder, deleted: false, created_at: creation_times[0])
          create(:example_hoarder, deleted: true, created_at: creation_times[1])
          create(:example_hoarder, deleted: false, created_at: creation_times[2])
        end

        it "returns oldest date" do
          expect(result).to eq(expected)
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

    describe "next_batch" do
      it "is implemented" do
        expect(subject.private_methods).to include(:next_batch)
      end

      describe "function" do
        before do
          expect(subject).to receive(:next_batch).and_call_original
        end

        context "next batch is cached" do
          before do
            subject.instance_variable_set(:@next_batch, batch_instance)
          end

          it "does not hit the database" do
            expect(subject).not_to receive(:retrieve_batch)
            subject.send(:next_batch)
          end

          it "leaves the batch cached" do
            expect(subject.instance_variable_get(:@next_batch)).to eq(batch_instance)
            subject.send(:next_batch)
            expect(subject.instance_variable_get(:@next_batch)).to eq(batch_instance)
          end

          it "returns the next batch" do
            expect(subject.send(:next_batch)).to eq(batch_instance)
          end
        end

        context "next batch is not cached" do
          it "hits the database" do
            expect(subject).to receive(:retrieve_batch)
            subject.send(:next_batch)
          end

          it "caches the next batch" do
            expect(subject.send(:next_batch_data_cached?)).to be(false)
            subject.send(:next_batch)
            expect(subject.send(:next_batch_data_cached?)).to be(true)
          end
        end

        it "returns next batch" do
          expect(subject.send(:next_batch)).to eq(batch_instance)
        end
      end
    end

    describe "next_batch_data_cached?" do
      it "is implemented" do
        expect(subject.private_methods).to include(:next_batch_data_cached?)
      end

      describe "function" do
        before do
          expect(subject).to receive(:next_batch_data_cached?).and_call_original
        end

        context "next batch is cached" do
          before do
            subject.instance_variable_set(:@next_batch, batch_instance)
          end

          it "returns true" do
            expect(subject.send(:next_batch_data_cached?)).to be(true)
          end
        end

        context "next batch is not cached" do
          it "returns false" do
            expect(subject.send(:next_batch_data_cached?)).to be(false)
          end
        end
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

      before do
        allow(hoarder_connection).to receive(:exec_query).and_return(batch_data)
        allow(subject).to receive(:absolute_limit_reached?).and_return(limit_reached)
      end

      context "batch_query is missing" do
        let(:limit_reached) { false }
        let(:batch_query) { nil }

        it "returns empty_batch" do
          expect(subject.send(:retrieve_batch)).to eq(empty_batch)
        end
      end

      context "batch_query is not missing" do
        context "limit is reached" do
          let(:limit_reached) { true }

          it "does not hit the database" do
            expect(hoarder_connection).not_to receive(:exec_query)
            subject.send(:retrieve_batch)
          end

          it "returns an empty batch" do
            expect(subject.send(:retrieve_batch)).to be(empty_batch)
          end
        end

        context "limit is not yet reached" do
          let(:deletion_hash) { { database_connection: hoarder_connection, deletion_query: delete_query } }
          let(:limit_reached) { false }

          it "uses batch_query to retrieve batch_data" do
            expect(batch_query).to receive(:fetch).and_return(fetch_query)
            expect(hoarder_connection).to receive(:exec_query).with(fetch_query)
            subject.send(:retrieve_batch)
          end

          it "uses retrieved batch_data to return Batch instance" do
            expect(::ActiverecordHoarder::Batch).to receive(:from_records).with(batch_data, deletion_hash)
            expect(subject.send(:retrieve_batch)).to be(batch_instance)
          end
        end
      end
    end

    describe "update_absolute_upper_limit" do
      before do
        subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit_before)
      end

      after do
        subject.send(:update_absolute_upper_limit)
        expect(subject.instance_variable_get(:@absolute_upper_limit)).to eq(absolute_upper_limit_expectation)
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

        it "sets absolute_upper_limit to end of lower_limit week" do
        end
      end
    end

    describe "update_limits" do
      RSpec.shared_examples "update position" do
        it "moves to the next interval starting at last upper_limit" do
          subject.send(:update_limits, false)
          expect(previous_upper_limit).not_to be(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(previous_upper_limit)
        end

        it "sets limit inclusion" do
          expect(subject.instance_variable_get(:@include_lower_limit)).to be(true)
          subject.send(:update_limits, false)
          expect(subject.instance_variable_get(:@include_lower_limit)).to be(false)
        end
      end

      let(:previous_upper_limit) { double("previous_upper_limit") }

      before do
        allow(subject).to receive(:update_absolute_upper_limit)
        allow(subject).to receive(:upper_limit).and_return(previous_upper_limit)
      end

      context "updating absolute upper" do
        let(:update_absolute) { true }

        it "updates absolute_upper_limit before updating lower_limit to upper_limit" do
          expect(subject).to receive(:update_absolute_upper_limit).ordered
          expect(subject).to receive(:upper_limit).ordered
          subject.send(:update_limits, update_absolute)
        end

        include_examples "update position"
      end

      context "not updating absolute upper" do
        let(:update_absolute) { false }

        it "does not update absolute_upper_limit" do
          expect(subject).not_to receive(:update_absolute_upper_limit)
          subject.send(:update_limits, update_absolute)
        end

        include_examples "update position"
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
        allow(subject).to receive(:update_query).and_call_original
      end

      it "reconstructs query" do
        expect(::ActiverecordHoarder::BatchQuery).to receive(:new).with(hoarder_class, lower_limit_override, upper_limit_from_override, {include_lower: true, include_upper: true})
        subject.send(:update_query)
        expect(subject.instance_variable_get(:@batch_query)).to be(new_query)
      end
    end
  end
end

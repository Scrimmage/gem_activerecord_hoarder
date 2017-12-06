require "spec_helper"

RSpec.describe ::ActiverecordHoarder::BatchCollector do
  subject { described_class.new(hoarder_class, lower_limit_override: lower_limit_override, max_count: max_count) }
  let(:absolute_limit_reached) { false }
  let(:batch_data) { double("batch_data") }
  let(:batch_instance) { double("batch_instance", present?: true, valid?: true) }
  let(:batch_query) { double("batch_query", delete: delete_query, fetch: fetch_query) }
  let(:delete_query) { "delete_query" }
  let(:delete_transaction) { double("delete_transaction") }
  let(:empty_batch) { double("empty_batch", present?: false) }
  let(:fetch_query) { "fetch_query" }
  let(:hoarder_class) { double("hoarder_class", connection: hoarder_connection) }
  let(:hoarder_connection) { double("hoarder_connection", exec_query: nil) }
  let(:lower_limit_override) { double("lower_limit_override", end_of_day: upper_limit_from_override, end_of_week: absolute_upper_limit) }
  let(:max_count) { nil }
  let(:upper_limit_from_override) { double("upper_limit_from_override") }
  let(:absolute_upper_limit) { double("absolute_upper_limit") }

  before do
    allow_any_instance_of(::ActiverecordHoarder::BatchCollector).to receive(:find_limits)
    allow_any_instance_of(::ActiverecordHoarder::BatchCollector).to receive(:update_query)
    subject.instance_variable_set(:@batch_query, batch_query)
    allow(::ActiverecordHoarder::Batch).to receive(:new).with(batch_data).and_return(batch_instance)
    allow(::ActiverecordHoarder::Batch).to receive(:new).with([]).and_return(empty_batch)
    allow(subject).to receive(:relative_upper_limit).and_return(upper_limit_from_override)
    allow(subject).to receive(:absolute_limit_reached?).and_return(absolute_limit_reached)
    allow(subject).to receive(:delete_transaction).and_return(delete_transaction)
    allow(subject).to receive(:next_batch).and_return(batch_instance)
    allow(hoarder_connection).to receive(:exec_query).and_return(batch_data)
    allow(lower_limit_override).to receive(:utc).and_return(lower_limit_override)
    allow(lower_limit_override).to receive(:beginning_of_day).and_return(lower_limit_override)
    allow(subject).to receive(:upper_limit).and_return(upper_limit_from_override)
  end

  describe "accuracy" do
    it "handles time accuracy gracefully"
  end

  describe "public" do
    describe "(removed) in_batches" do
      it "is removed" do
        expect(subject).not_to respond_to(:in_batches)
      end
    end

    describe "next" do
      before do
        expect(subject).to receive(:next).and_call_original
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

      it "updates limit and query" do
        expect(subject).to receive(:update_limits_and_query)
        subject.next
      end
    end

    describe "next?" do
      context "upper limit not reached" do
        it "returns true" do
          expect(subject.next?).to be(true)
        end
      end

      context "upper limit reached" do
        let(:absolute_limit_reached) { true }

        it "returns false" do
          expect(subject.next?).to be(false)
        end
      end
    end

    describe "next_valid" do
      before do
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

      it "updates limit and query" do
        expect(subject).to receive(:update_limits_and_query)
        subject.next_valid
      end
    end
  end

  describe "private" do
    describe "absolute_upper_limit" do
      let(:eoyesterday) { 1.day.ago.utc.end_of_day }

      before do
        subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit)
      end

      context "no abs. upper limit given" do
        let(:absolute_upper_limit) { nil }

        it "returns end of yesterday" do
          expect(subject.send(:absolute_upper_limit)).to eq(eoyesterday)
        end
      end

      context "abs. upper limit given" do
        context "abs. upper limit later than end of yesterday" do
          let(:absolute_upper_limit) { Time.now.utc.beginning_of_day }

          it "returns end of yesterday" do
            expect(subject.send(:absolute_upper_limit)).to eq(eoyesterday)
          end
        end

        context "abs. upper limit earlier than end of yesterday" do
          let(:absolute_upper_limit) { 1.day.ago.utc.end_of_day - 1.second }
          
          it "returns absolute upper limit override" do
            expect(subject.send(:absolute_upper_limit)).to eq(absolute_upper_limit)
          end
        end
      end
    end

    describe "absolute_limit_reached?" do
      let(:lower_limit_override) { 1.day.ago - 1.second }
      let(:absolute_upper_limit) { 1.day.ago }

      before do
        allow(subject).to receive(:absolute_limit_reached?).and_call_original
        subject.instance_variable_set(:@absolute_upper_limit, absolute_upper_limit)
      end

      context "lower_limit is below absolute_upper_limit" do
        it "returns false" do
          expect(subject.send(:absolute_limit_reached?)).to be(false)
        end
      end

      context "lower_limit is not below absolute_upper_limit" do
        let(:absolute_upper_limit) { lower_limit_override - 1.day }

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

      RSpec.shared_examples "return empty_batch" do
        it "sets @batch to be an empty_batch and returns it" do
          expect(subject.send(:collect_batch)).to be(empty_batch)
        end
      end

      context "limit reached" do
        let(:absolute_limit_reached) { true }

        include_examples "return empty_batch"
      end

      context "batch_query not present" do
        let(:batch_query) { nil }

        include_examples "return empty_batch"
      end

      context "limit not reached and batch_query present" do
        context "record not new" do
          let(:date2) { date1 }

          include_examples "return empty_batch"
        end

        context "record new" do
          it "sets @batch from records and returns it" do
            expect(subject.send(:collect_batch)).to be(ensured_batch)
          end
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
          expect(subject.send(:ensuring_new_records) { new_batch } ).to eq(empty_batch)
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

    describe "delete_transaction" do
      let(:delete_transaction) { subject.send(:delete_transaction) }

      it "returns can be called" do
        expect(delete_transaction).to respond_to(:call)
      end

      it "calls exec_query with delete_query on hoarder_connection" do
        expect(hoarder_connection).to receive(:exec_query).with(delete_query)
        delete_transaction.call
      end
    end

    describe "find_limits" do
      before do
        allow(subject).to receive(:get_oldest_datetime).and_return(lower_limit_override)
        allow(subject).to receive(:find_limits).and_call_original
        subject.instance_variable_set(:@lower_limit_override, lower_limit_override)
      end

      context "with lower limit is overridden" do
        it "does not modify lower limit and returns true" do
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(true)
          expect(subject.instance_variable_get(:@lower_limit)).not_to eq(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(lower_limit_override)
        end
      end

      context "lower limit is not overridden" do
        before do
          subject.remove_instance_variable(:@lower_limit)
        end

        it "sets inner_lower_limit from records and returns true" do
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(false)
          expect(subject.send(:find_limits)).to eq(true)
          expect(subject.instance_variable_defined?(:@lower_limit)).to be(true)
          expect(subject.instance_variable_get(:@lower_limit)).not_to eq(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(lower_limit_override)
        end
      end

      context "without any source for limits" do
        let(:lower_limit_override) { nil }

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
          allow(subject).to receive(:collect_batch).and_return(batch_instance)
        end

        context "next batch is cached" do
          before do
            subject.instance_variable_set(:@next_batch, batch_instance)
          end

          it "does not hit the database" do
            expect(subject).not_to receive(:collect_batch)
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

          it "returns next batch" do
            expect(subject.send(:next_batch)).to eq(batch_instance)
          end
        end

        context "next batch is not cached" do
          it "hits the database" do
            expect(subject).to receive(:collect_batch)
            subject.send(:next_batch)
          end

          it "caches the next batch" do
            expect(subject.send(:next_batch_data_cached?)).to be(false)
            subject.send(:next_batch)
            expect(subject.send(:next_batch_data_cached?)).to be(true)
          end

          it "returns next batch" do
            expect(subject.send(:next_batch)).to eq(batch_instance)
          end
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
      context "absolute_upper_limit yet unknown" do
        let(:absolute_upper_limit) { nil }

        it "returns relative_upper_limit" do
          expect(subject.send(:upper_limit)).to eq(upper_limit_from_override)
        end
      end

      context "absolute_upper_limit known" do
        let(:absolute_upper_limit) { 2.days.ago }

        context "relative_upper_limit less than absolute_upper_limit" do
          let(:relative_upper_limit) { 3.days.ago }

          it "returns relative_upper_limit" do
            expect(subject.send(:upper_limit)).to eq(upper_limit_from_override)
          end
        end

        context "relative_upper_limit more than absolute_upper_limit" do
          let(:relative_upper_limit) { 1.day.ago }

          it "returns absolute_upper_limit" do
            expect(subject.send(:upper_limit)).to eq(upper_limit_from_override)
          end
        end
      end
    end

    describe "pop_next_batch" do
      before do
        subject.instance_variable_set(:@next_batch, batch_instance)
      end

      it "returns next_batch" do
        expect(subject.send(:pop_next_batch)).to eq(batch_instance)
      end

      it "unsets cached" do
        expect(subject.instance_variable_get(:@next_batch)).to be(batch_instance)
        subject.send(:pop_next_batch)
        expect(subject.instance_variable_get(:@next_batch)).to be(nil)
      end
    end

    describe "relative_upper_limit" do
      let(:lower_limit) { 3.days.ago }
      let(:relative_upper_limit) { (lower_limit + 1.day).utc.beginning_of_day }

      before do
        subject.instance_variable_set(:@lower_limit, lower_limit)
        allow(subject).to receive(:relative_upper_limit).and_call_original
      end

      it "returns upper limit in respect to lower limit" do
        expect(subject.send(:relative_upper_limit).iso8601(3)).to eq(relative_upper_limit.iso8601(3))
      end
    end

    describe "retrieve_batch" do
      let(:deletion_hash) { { delete_transaction: delete_transaction } }

      before do
        allow(::ActiverecordHoarder::Batch).to receive(:new).with(batch_data, deletion_hash).and_return(batch_instance)
      end

      it "uses batch_query to retrieve batch_data" do
        expect(batch_query).to receive(:fetch).and_return(fetch_query)
        expect(hoarder_connection).to receive(:exec_query).with(fetch_query)
        subject.send(:retrieve_batch)
      end

      it "uses retrieved batch_data to return Batch instance" do
        expect(::ActiverecordHoarder::Batch).to receive(:new).with(batch_data, deletion_hash)
        expect(subject.send(:retrieve_batch)).to be(batch_instance)
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
          expect(upper_limit_from_override).not_to be(nil)
          expect(subject.instance_variable_get(:@lower_limit)).to eq(upper_limit_from_override)
        end

        it "sets limit inclusion" do
          expect(subject.instance_variable_get(:@include_lower_limit)).to be(true)
          subject.send(:update_limits, false)
          expect(subject.instance_variable_get(:@include_lower_limit)).to be(false)
        end
      end

      context "updating absolute upper" do
        let(:update_absolute) { true }

        it "updates absolute_upper_limit before updating lower_limit to upper_limit" do
          expect(subject).to receive(:update_absolute_upper_limit).ordered
          expect(subject).to receive(:relative_upper_limit).ordered
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
      let(:new_query) { double("new query") }
      let(:old_query) { double("old query") }
      let(:upper_limit) { double("upper_limit") }

      before do
        subject.instance_variable_set(:@batch_query, old_query)
        allow(subject).to receive(:update_query).and_call_original
        allow(subject).to receive(:upper_limit).and_return(upper_limit)
      end

      it "reconstructs query" do
        expect(::ActiverecordHoarder::BatchQuery).to receive(:new).with(hoarder_class, lower_limit_override, upper_limit, {include_lower: true, include_upper: true}).and_return(new_query)
        subject.send(:update_query)
        expect(subject.instance_variable_get(:@batch_query)).to be(new_query)
      end
    end
  end
end

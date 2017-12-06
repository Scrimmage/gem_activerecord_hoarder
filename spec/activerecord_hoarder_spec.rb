require "spec_helper"

RSpec.describe ActiverecordHoarder do
  FREEZE_TIME = (Date.today.beginning_of_week - 3).to_time(:utc).end_of_day

  around(:each) do |example|
    current_zone = Time.zone
    Time.zone = "America/Chicago"
    Timecop.freeze(FREEZE_TIME) do
      example.run
    end
    Time.zone = current_zone
  end

  it "is tested with timecop" do
    expect(Time.now).to eq(FREEZE_TIME)
  end

  it "has a version number" do
    expect(ActiverecordHoarder::VERSION).not_to be nil
  end

  it "extends ::ActiveRecord::Base with acts_as_hoarder" do
    expect(::ActiveRecord::Base.methods).to include(:acts_as_hoarder)
  end

  describe "acts_as_hoarder" do
    context "successfully included in ActiveRecord model" do
      it "extends with public class method .hoard" do
        expect(ExampleHoarder.methods).to include(:hoard)
      end
    end
  end

  describe "record archiving" do
    let(:archive_data) {
      @archivable_records.group_by { |item|
        item.created_at.getutc.to_date
      } .collect { |date, group|
        JSON.pretty_generate(group.collect(&:serializable_hash))
      }
    }
    let(:storage) { double("storage", store_data: true) }

    before :each do
      allow(::ActiverecordHoarder::Storage).to receive(:new).and_return(storage)
    end

    context "with records only in current week" do
      before :each do
        @archivable_records = create_list(
          :examples_in_range,
          20,
          deleted: true,
          start_time: Time.now.getutc.beginning_of_week,
          end_time: (Date.today - 1).to_time(:utc).end_of_day
        )
        @non_archivable_records = create_list(
          :examples_on_date,
          4,
          deleted: true,
          records_date: Date.today
        )
        ExampleHoarder.hoard
      end

      it "ignores current day" do
        expect(ExampleHoarder.unscoped.to_a).to include(*@non_archivable_records)
      end

      it "archives days previous to #{FREEZE_TIME.beginning_of_day}" do
        expect(ExampleHoarder.unscoped.to_a).not_to include(*@archivable_records)
      end
    end

    context "with records in multiple weeks, non-deleted records mixed in and trailing" do
      CURRENT_TIME = FREEZE_TIME
      BEGINNING_OF_CURRENT_WEEK = CURRENT_TIME.getutc.beginning_of_week
      BEGINNING_OF_LAST_WEEK = (CURRENT_TIME - 1.week).getutc.beginning_of_week
      BEGINNING_OF_SECOND_ARCHIVABLE_RANGE = (BEGINNING_OF_LAST_WEEK + 4.days).beginning_of_day
      DAY_PREVIOUS_TO_LAST_WEEK = (BEGINNING_OF_LAST_WEEK - 1.day).to_date
      END_OF_FIRST_ARCHIVABLE_RANGE = (BEGINNING_OF_LAST_WEEK + 2.days).end_of_day
      END_OF_LAST_WEEK = BEGINNING_OF_LAST_WEEK.end_of_week
      MIXED_DAY_LAST_WEEK = (BEGINNING_OF_LAST_WEEK + 3.days).to_date

      before do
        @archivable_records = create_list(
          :examples_in_range,
          20,
          deleted: true,
          end_time: END_OF_FIRST_ARCHIVABLE_RANGE,
          start_time: BEGINNING_OF_LAST_WEEK
        ) + create_list(
          :examples_in_range,
          20,
          deleted: true,
          end_time: END_OF_LAST_WEEK,
          start_time: BEGINNING_OF_SECOND_ARCHIVABLE_RANGE
        )
        @non_archivable_records = create_list(
          :examples_on_date,
          2,
          deleted: true,
          records_date: DAY_PREVIOUS_TO_LAST_WEEK
        ) + create_list(
          :examples_on_date,
          1,
          deleted: false,
          records_date: DAY_PREVIOUS_TO_LAST_WEEK
        ) + create_list(
          :examples_on_date,
          4,
          deleted: true,
          records_date: MIXED_DAY_LAST_WEEK,
        ) + create_list(
          :examples_on_date,
          2,
          deleted: false,
          records_date: MIXED_DAY_LAST_WEEK
        )
        @out_of_range_records = create_list(
          :examples_in_range,
          2,
          deleted: true,
          end_time: CURRENT_TIME,
          start_time: BEGINNING_OF_CURRENT_WEEK
        ) + create_list(
          :examples_in_range,
          2,
          deleted: false,
          end_time: CURRENT_TIME,
          start_time: BEGINNING_OF_CURRENT_WEEK
        )
        @all_records = @archivable_records + @non_archivable_records + @out_of_range_records
        ExampleHoarder.hoard
      end

      it "skips records from days with active records" do
        expect(ExampleHoarder.unscoped.to_a).to include(*@non_archivable_records)
      end

      it "archives one week of fully deleted records" do
        expect(ExampleHoarder.unscoped.to_a).not_to include(*@archivable_records), "expected to not include archivable records in time range:\n#{BEGINNING_OF_LAST_WEEK} to #{END_OF_FIRST_ARCHIVABLE_RANGE} and #{BEGINNING_OF_SECOND_ARCHIVABLE_RANGE} to #{END_OF_LAST_WEEK}\n\n #{(@archivable_records.collect(&:id))}\nBut included:\n#{(ExampleHoarder.unscoped.to_a).collect(&:id)}\n\n and archived:\n#{(@all_records - ExampleHoarder.unscoped.to_a).collect(&:id)}\n\nOriginally included: \n #{@all_records.pretty_inspect}"
      end

      it "stops after one week" do
        expect(ExampleHoarder.unscoped.to_a).to include(*@out_of_range_records)
      end
    end
  end

  describe "workflow" do
    let(:batch_instance) { double("batch", present?: true, delete_records!: nil) }
    let(:collector) { ::ActiverecordHoarder::BatchCollector.new(ExampleHoarder) }
    let(:storage) { double }

    before do
      allow(::ActiverecordHoarder::Storage).to receive(:new).and_return(storage)
      allow(::ActiverecordHoarder::BatchCollector).to receive(:new).and_return(collector)
      allow(collector).to receive(:next?).and_return(true, true, false)
      allow(collector).to receive(:next_valid).and_return(batch_instance)
    end

    after do
      ExampleHoarder.hoard
    end

    it "fully processes one record batch before moving on to the next" do
      expect(collector).to receive(:next_valid).and_return(batch_instance)
      expect(storage).to receive(:store_data).and_return(true)
      expect(batch_instance).to receive(:delete_records!)
      expect(collector).to receive(:next_valid).and_return(nil)
    end

    it "does not delete a record that wasn't successfully archived" do
      expect(storage).to receive(:store_data).and_return(false)
      expect(collector).not_to receive(:destroy_current_records!)
    end
  end
end

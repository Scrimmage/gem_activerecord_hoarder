require "spec_helper"

RSpec.describe ActiverecordHoarder do

  around(:all) do |example|
    current_zone = Time.zone
    Time.zone = "America/Chicago"
    Timecop.freeze((Date.today.beginning_of_week - 3).to_time(:utc).end_of_day) do
      example.run
    end
    Time.zone = current_zone
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
    let(:storage) { double }

    before :each do
      allow(::ActiverecordHoarder::Storage).to receive(:new).and_return(storage)
      allow(storage).to receive(:store_data).and_return(true)
    end

    context "with records only in current week" do
      before do
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

      it "archives previous days" do
        expect(ExampleHoarder.unscoped.to_a).not_to include(*@archivable_records)
      end
    end

    context "with records in multiple weeks, non-deleted records mixed in and trailing" do
      before do
        @archivable_records = create_list(
          :examples_in_range,
          20,
          deleted: true,
          end_time: (1.week.ago.getutc.beginning_of_week + 2.days).end_of_day,
          start_time: 1.week.ago.getutc.beginning_of_week
        ) + create_list(
          :examples_in_range,
          20,
          deleted: true,
          end_time: 1.week.ago.getutc.end_of_week,
          start_time: 1.week.ago.getutc.beginning_of_week + 4.days
        )
        @non_archivable_records = create_list(
          :examples_on_date,
          2,
          deleted: true,
          records_date: (1.week.ago.getutc.beginning_of_week - 1.day).to_date
        ) + create_list(
          :examples_on_date,
          1,
          deleted: false,
          records_date: (1.week.ago.getutc.beginning_of_week - 1.day).to_date
        ) + create_list(
          :examples_on_date,
          4,
          deleted: true,
          records_date: (1.week.ago.getutc.beginning_of_week + 3.days).to_date,
        ) + create_list(
          :examples_on_date,
          2,
          deleted: false,
          records_date: (1.week.ago.getutc.beginning_of_week + 3.days).to_date
        )
        @out_of_range_records = create_list(
          :examples_in_range,
          2,
          deleted: true,
          end_time: Time.now,
          start_time: Time.now.getutc.beginning_of_week
        ) + create_list(
          :examples_in_range,
          2,
          deleted: false,
          end_time: Time.now,
          start_time: Time.now.getutc.beginning_of_week
        )
        ExampleHoarder.hoard
      end

      it "skips records from days with active records" do
        expect(ExampleHoarder.unscoped.to_a).to include(*@non_archivable_records)
      end

      it "archives one week of fully deleted records" do
        expect(ExampleHoarder.unscoped.to_a).not_to include(*@archivable_records)
      end

      it "stops after one week" do
        expect(ExampleHoarder.unscoped.to_a).to include(*@out_of_range_records)
      end
    end
  end

  describe "workflow" do
    let(:batch1) { double }
    let(:collector) { ::ActiverecordHoarder::RecordCollector.new(ExampleHoarder) }
    let(:storage) { double }

    before do
      allow(::ActiverecordHoarder::Storage).to receive(:new).and_return(storage)
      allow(::ActiverecordHoarder::RecordCollector).to receive(:new).and_return(collector)
      allow(collector).to receive(:collect_batch).and_return(true, false)
      allow(collector).to receive(:batch_data_cached?).and_return(true)
      allow_any_instance_of(::ActiverecordHoarder::BatchArchiver).to receive(:compose_key).and_return("key")
      allow(collector).to receive(:destroy_current_records!)
    end

    after do
      ExampleHoarder.hoard
    end

    it "fully processes one record batch before moving on to the next" do
      expect(collector).to receive(:collect_batch)
      expect(storage).to receive(:store_data).and_return(true)
      expect(collector).to receive(:destroy_current_records!)
      expect(collector).to receive(:collect_batch)
    end

    it "does not delete a record that wasn't successfully archived" do
      expect(storage).to receive(:store_data).and_return(false)
      expect(collector).not_to receive(:destroy_current_records!)
    end
  end
end
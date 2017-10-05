require "spec_helper"

class Example < ActiveRecord::Base
  batch_archivable
  acts_as_paranoid
end

RSpec.describe BatchArchiving do
  it "has a version number" do
    expect(BatchArchiving::VERSION).not_to be nil
  end

  it "extends ::ActiveRecord::Base with batch_archivable" do
    expect(::ActiveRecord::Base.methods).to include(:batch_archivable)
  end

  describe "batch_archivable" do
    context "successfully included in ActiveRecord model" do
      it "extends with public class method .archive_batch" do
        expect(Example.methods).to include(:archive_batch)
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

    around(:each) do |example|
      current_zone = Time.zone
      Time.zone = "America/Chicago"
      Timecop.freeze((Date.today.beginning_of_week + 4).in_time_zone) do
        example.run
      end
      Time.zone = current_zone
    end

    before :each do
      allow(::BatchArchiving::Storage).to receive(:store_archive).and_return(true)
      Example.archive_batch
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
      end

      it "ignores current day" do
        expect(Example.unscoped.to_a).to include(*@non_archivable_records)
      end

      it "archives previous days" do
        expect(Example.unscoped.to_a).not_to include(*@archivable_records)
        expect(::BatchArchiving::Storage.get_records).to eq(archive_data)
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
      end

      it "skips records from days with active records" do
        expect(Example.unscoped.to_a).to include(*@non_archivable_records)
      end

      it "archives one week of fully deleted records" do
        expect(Example.unscoped.to_a).not_to include(*@archivable_records)
        expect(::BatchArchiving::Storage.get_records).to eq(archive_data)
      end

      it "stops after one week" do
        expect(Example.unscoped.to_a).to include(*@out_of_range_records)
      end
    end
  end

  describe "workflow" do
    let(:collector) { ::BatchArchiving::RecordCollector.new(Example) }
    let(:batch1) { double }

    before do
      allow(::BatchArchiving::RecordCollector).to receive(:new).and_return(collector)
      allow(collector).to receive(:retrieve_batch).and_return(true, false)
      allow(collector).to receive(:destroy_current_records!)
    end

    it "fully processes one record batch before moving on to the next" do
      expect(collector).to receive(:retrieve_batch)
      expect(::BatchArchiving::Serializer).to receive(:create_archive)
      expect(::BatchArchiving::Storage).to receive(:store_archive).and_return(true)
      expect(collector).to receive(:destroy_current_records!)
      expect(collector).to receive(:retrieve_batch)
      Example.archive_batch
    end

    it "does not delete a record that wasn't successfully archived" do
      expect(::BatchArchiving::Storage).to receive(:store_archive).and_return(false)
      expect(collector).not_to receive(:destroy_current_records!)
      Example.archive_batch
    end
  end
end

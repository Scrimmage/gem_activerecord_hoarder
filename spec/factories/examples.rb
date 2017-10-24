def datetimes_in_range(n, step: 5, start:, stop:)
  seconds_in_range = stop - start
  seconds_ago = Time.now.getutc - stop
  ((n*(step.hours+1.minute + 1.second)) % seconds_in_range + seconds_ago).seconds.ago
end

FactoryGirl.define do
  factory :example_archivable do
    transient do
      deleted false
    end

    after :build do |record, evaluator|
      if evaluator.deleted
        record.deleted_at = record.created_at
      end
    end
  end

  factory :examples_in_range, parent: :example_archivable do
    transient do
      end_time Time.now
      start_time 2.weeks.ago
      step 5
    end

    sequence(:created_at, 0) { |n| datetimes_in_range(n, step: step, start: start_time, stop: end_time) }
  end

  factory :examples_on_date, parent: :example_archivable do
    transient do
      records_date Date.today - 1
      step 5
    end

    sequence(:created_at, 0) { |n|
      created_at_value = datetimes_in_range(n, step: step, start: records_date.to_time(:utc), stop: records_date.to_time(:utc).end_of_day)
    }
  end
end

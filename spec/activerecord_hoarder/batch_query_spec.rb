require 'spec_helper'

RSpec.shared_examples "limit inclusion" do |comparison, limit|
  FULL_COMPARISON_TEMPLATE = "%{comparison} \"%{limit}\""

  after do
    limit_regexp = Regexp.new(FULL_COMPARISON_TEMPLATE % {
      comparison: full_comparison,
      limit: limit
    })
    expect(limited_query).to match(limit_regexp)
  end

  context "excluded" do
    let(:full_comparison) { comparison }
    let(:excluding) { true }

    it "doesn't allow limit" do
    end
  end

  context "included" do
    let(:full_comparison) { comparison + "=" }
    let(:excluding) { false }

    it "allows limit" do
    end
  end
end

RSpec.shared_examples "limit conditions" do |method, limits|
  let(:limited_query) { query_object.send(method) }
  let(:query_kwargs) { { exclude_lower: exclude_lower, exclude_upper: exclude_upper } }
  let(:query_object) { described_class.new(*query_args, **query_kwargs) }

  let(:exclude_lower) { false }
  let(:exclude_upper) { false }

  describe "lower limit" do
    let(:exclude_lower) { excluding }

    include_examples "limit inclusion", ">", limits[0]
  end

  describe "upper limit" do
    let(:exclude_upper) { excluding }

    include_examples "limit inclusion", "<", limits[1]
  end
end

RSpec.describe ::ActiverecordHoarder::BatchQuery do
  LOWER_LIMIT = "LOWERLIMIT"
  UPPER_LIMIT = "UPPERLIMIT"

  subject { described_class.new(*query_args) }

  let(:model_class) { double("some model",
    table_name: table_name,
    column_names: ["column0", "column1", "column2"]) }
  let(:lower_limit) { LOWER_LIMIT }
  let(:upper_limit) { UPPER_LIMIT }
  let(:query_args) { [model_class, lower_limit, upper_limit] }
  let(:table_name) { "some_table" }

  describe "delete" do
    let(:subject_query) { subject.delete }

    it "returns subject_query for deleting full date of records" do
      expect(subject).to respond_to(:delete)
      expect(subject_query).to match(/DELETE FROM/i)
    end

    include_examples "limit conditions", :delete, [LOWER_LIMIT, UPPER_LIMIT]
  end

  describe "fetch" do
    let(:subject_query) { subject.fetch }

    it "returns subject_query for fetching records" do
      expect(subject).to respond_to(:fetch)
      expect(subject_query).not_to match(/DELETE/i)
      expect(subject_query).to match(/SELECT/i)
    end

    include_examples "limit conditions", :fetch, [LOWER_LIMIT, UPPER_LIMIT]
  end
end

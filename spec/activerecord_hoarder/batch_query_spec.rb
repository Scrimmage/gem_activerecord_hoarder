require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::BatchQuery do
  subject { described_class.new(*query_args) }

  let(:model_class) { double("some model",
    table_name: table_name,
    column_names: ["column0", "column1", "column2"]) }
  let(:outer_limit_lower) { "LOWERLIMIT" }
  let(:outer_limit_upper) { "UPPERLIMIT" }
  let(:query_args) { [model_class, outer_limit_lower, outer_limit_upper] }
  let(:table_name) { "some_table" }

  describe "delete" do
    let(:delete_query) { subject.delete }

    it "returns query for deleting full date of records" do
      expect(subject).to respond_to(:delete)
      expect(delete_query).to match("DELETE FROM")
      expect(delete_query).to match(outer_limit_lower)
      expect(delete_query).to match(outer_limit_upper)
    end
  end

  describe "fetch" do
    let(:fetch_query) { subject.fetch }

    it "returns query for fetching records" do
      expect(subject).to respond_to(:fetch)
      expect(fetch_query).not_to match("delete")
      expect(fetch_query).to match("SELECT")
      expect(fetch_query).to match(outer_limit_lower)
      expect(fetch_query).to match(outer_limit_upper)
    end
  end
end

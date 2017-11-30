require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::BatchQuery do
  subject { described_class.new(*query_args) }

  let(:model_class) { double("some model",
    table_name: table_name,
    column_names: ["column0", "column1", "column2"]) }
  let(:inner_lower_limit) { "LOWERLIMIT" }
  let(:inner_upper_limit) { "UPPERLIMIT" }
  let(:query_args) { [model_class, inner_lower_limit, inner_upper_limit] }
  let(:sql_condition) { "BETWEEN \"#{inner_lower_limit}\" AND \"#{inner_upper_limit}\"" }
  let(:table_name) { "some_table" }

  describe "delete" do
    let(:delete_query) { subject.delete }

    it "returns query for deleting full date of records" do
      expect(subject).to respond_to(:delete)
      expect(delete_query).to match(/DELETE FROM/i)
      expect(delete_query).to match(sql_condition)
    end
  end

  describe "fetch" do
    let(:fetch_query) { subject.fetch }

    it "returns query for fetching records" do
      expect(subject).to respond_to(:fetch)
      expect(fetch_query).not_to match(/DELETE/i)
      expect(fetch_query).to match(/SELECT/i)
      expect(fetch_query).to match(sql_condition)
    end
  end
end

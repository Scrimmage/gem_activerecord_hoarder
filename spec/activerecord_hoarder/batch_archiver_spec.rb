require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::BatchArchiver do
  let(:model_class) { double("Record", table_name: "records") }

  it "creates instance that can archive_batch" do
    allow(::ActiverecordHoarder::Storage).to receive(:new).and_return(double)
    expect(described_class.new(model_class)).to respond_to(:archive_batch)
  end
end

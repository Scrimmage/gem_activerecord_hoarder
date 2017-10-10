require 'spec_helper'

RSpec.describe ::BatchArchiving::BatchArchiver do
  it "creates instance that can archive_batch" do
    allow(::BatchArchiving::Storage).to receive(:new).and_return(double)
    expect(described_class.new(nil)).to respond_to(:archive_batch)
  end
end

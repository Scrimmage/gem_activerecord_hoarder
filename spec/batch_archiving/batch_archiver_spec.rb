require 'spec_helper'

RSpec.describe ::BatchArchiving::BatchArchiver do
  it "creates instance that can archive_batch" do
    expect(described_class.new(nil)).to respond_to(:archive_batch)
  end
end

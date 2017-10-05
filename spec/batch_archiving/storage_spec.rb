require 'spec_helper'

RSpec.describe ::BatchArchiving::Storage do
  it "can store records" do
    expect(described_class).to respond_to(:store_archive)
  end

  it "can retrieve records" do
    expect(described_class).to respond_to(:retrieve_records_from_archive)
  end
end

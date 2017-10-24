require 'spec_helper'

RSpec.describe ::BatchArchiving::Serializer do
  it "has class method for serialization" do
    expect(described_class).to respond_to(:create_archive)
  end
end

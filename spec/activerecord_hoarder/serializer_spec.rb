require 'spec_helper'

RSpec.describe ::ActiverecordHoarder::Serializer do
  it "has class method for serialization" do
    expect(described_class).to respond_to(:serialize)
  end
end

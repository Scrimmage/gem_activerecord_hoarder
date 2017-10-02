require 'spec_helper'

RSpec.describe ::BatchArchiving::BatchArchiver do
  let(:class_double) { double("class") }

  it "is initialized with a model" do
    expect(described_class.new(class_double).instance_variable_get(:@model)).to be(class_double)
  end
end

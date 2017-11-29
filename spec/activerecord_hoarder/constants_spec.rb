require "spec_helper"

RSpec.describe ::ActiverecordHoarder::Constants do
  it "defines time limiting column" do
    expect(defined?(::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN)).to eq("constant")
  end
end

require "spec_helper"

RSpec.describe BatchArchiving do
  it "has a version number" do
    expect(BatchArchiving::VERSION).not_to be nil
  end

  it "extends ::ActiveRecord::Base with batch_archivable" do
    expect(::ActiveRecord::Base.methods).to include(:batch_archivable)
  end

  describe "batch_archivable" do
    context "included in ActiveRecord model" do
      let(:example_model_class) {
        class Example < ActiveRecord::Base
          batch_archivable
        end
        Example
      }

      it "extends with public class method .archive_batch" do
        expect(example_model_class.methods).to include(:archive_batch)
      end
    end
  end
end

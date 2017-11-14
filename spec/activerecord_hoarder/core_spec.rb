require 'spec_helper'

RSpec.describe 'ActiverecordHoarder::Core' do
  context 'included and instantiated' do
    describe 'hoard' do
      it "it works, no questions asked" do
        expect(::ActiverecordHoarder::Storage).to receive(:new).and_return(double)
        expect_any_instance_of(::ActiverecordHoarder::BatchArchiver).to receive(:archive_batch)
        expect{ ExampleHoarder.hoard }.not_to raise_error
      end
    end
  end
end

require 'spec_helper'

RSpec.describe 'ActiverecordHoarder::Core' do
  context 'included and instantiated' do
    before do
      expect(::ActiverecordHoarder::Storage).to receive(:new).and_return(double)
      expect_any_instance_of(::ActiverecordHoarder::BatchArchiver).to receive(:archive_batch)
    end

    describe 'hoard' do
      it "it works, no questions asked" do
        expect{ ExampleHoarder.hoard }.not_to raise_error
      end
    end

    describe 'hoard_single' do
      it "sets max_count to 1 and proceeds as otherwise" do
        expect{ ExampleHoarder.hoard_single }.not_to raise_error
      end
    end
  end
end

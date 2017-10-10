require 'spec_helper'

class Example < ActiveRecord::Base
  batch_archivable
end

RSpec.describe 'BatchArchiving::Core' do
  context 'included and instantiated' do
    describe 'archive_batch' do
      it "it works, no questions asked" do
        expect(::BatchArchiving::Storage).to receive(:new).and_return(double)
        expect_any_instance_of(::BatchArchiving::BatchArchiver).to receive(:archive_batch)
        expect{ Example.archive_batch }.not_to raise_error
      end
    end
  end
end

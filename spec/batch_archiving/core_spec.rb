require 'spec_helper'

class ExampleArchivable < ActiveRecord::Base
  attr_accessor :created_at, :deleted_at

  batch_archivable

end

RSpec.describe 'BatchArchiving::Core' do
  context 'included and instantiated' do
    describe 'archive_batch' do
      it "does something useful" do
        expect{ ExampleArchivable.archive_batch }.not_to raise_error
      end
    end
  end
end

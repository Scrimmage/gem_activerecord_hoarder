require 'spec_helper'

class Example < ActiveRecord::Base
  batch_archivable
end

RSpec.describe 'BatchArchiving::Core' do
  context 'included and instantiated' do
    describe 'archive_batch' do
      it "does something useful" do
        expect{ Example.archive_batch }.not_to raise_error
      end
    end
  end
end

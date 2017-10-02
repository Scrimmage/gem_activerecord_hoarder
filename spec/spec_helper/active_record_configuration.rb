require 'nulldb_rspec'

NullDB.configure { |ndb|
  def ndb.project_root
    File.join(__dir__, '../../')
  end
}

ActiveRecord::Base.establish_connection adapter: :nulldb

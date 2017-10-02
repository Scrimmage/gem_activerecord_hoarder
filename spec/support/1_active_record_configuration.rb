ActiveRecord::Base.establish_connection(
  adapter: :postgresql,
)

database_name = :batch_archiving_rspec
ActiveRecord::Base.connection.drop_database(database_name)
ActiveRecord::Base.connection.create_database(database_name)

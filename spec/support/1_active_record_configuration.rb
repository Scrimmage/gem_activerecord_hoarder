database_name = "batch_archiving_rspec.sqlite3"

ActiveRecord::Base.establish_connection(
  adapter: :sqlite3,
  database: database_name
)

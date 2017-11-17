file_location=$(pwd)"/config/dbspec_rspec.yml"

if [ -e file_location ]
then
  echo "$file_location found"
else
  echo "setting up database spec"
  touch config/dbspec_rspec.yml
  echo "adapter: sqlite3" >> config/dbspec_rspec.yml
  echo "database: activerecord_hoarder_rspec.sqlite3" >> config/dbspec_rspec.yml
fi

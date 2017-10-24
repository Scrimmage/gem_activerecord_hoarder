

ActiveRecord::Base.establish_connection(YAML.load_file("config/dbspec_rspec.yml"))

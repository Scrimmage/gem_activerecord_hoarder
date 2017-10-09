storage_options = YAML.load_file("config/batch_archiving_rspec.yml")
::BatchArchiving::Storage.configure(storage: :aws_s3, storage_options: storage_options)

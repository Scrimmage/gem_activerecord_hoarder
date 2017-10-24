# BatchArchiving

archive records in batches


Add archiving functionality to a model:
```
class ExampleModel < ActiveRecord::Base
  batch_archivable
end
```
and to use functionality:
```
storage_id = :aws_s3 # currently no other storages implemented
storage_options = {
  access_key_id: <aws_access_key_id>,
  acl: <acl>, # default 'private'
  bucket: <aws bucket>,
  bucket_sub_dir: <aws bucket sub directory>, # optional
  region: <aws region>,
  secret_access_key: <aws_secret_access_key>
}
::BatchArchiving::Storage.configure(storage: storage_id, storage_options: storage_options)

ExampleModel.archive_batch
```

Should result in records stored on AWS S3
with keys: `<bucket_sub_dir>/<table_name>/<year>/<month>/<year>-<month>-<day>.json`
and content: `<pretty formatted json model serializations>`

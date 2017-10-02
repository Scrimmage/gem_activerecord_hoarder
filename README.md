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
ExampleModel.archive_batch
```

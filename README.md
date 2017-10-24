# BatchArchiving

archive records in batches

## 1 Use

### 1.1 add archiving functionality to a model
```
class ExampleModel < ActiveRecord::Base
  batch_archivable
end
```

### 1.2  archiving records
from console:
```
ExampleModel.archive_batch
```
will create S3 entries with keys: `<bucket_sub_dir>/<table_name = example_models>/<year>/<month>/<year>-<month>-<day>.json` and content: `<pretty formatted json model serializations>`

### 1.3 restoring records
from console:
```
ExampleModel.restore_date(Date.new(<Y>,<m>,<d>))
```

## 2 Development

### 2.0 initial setup

Make a clone. Make a branch. Install dependencies.

### 2.1 playing around

#### Configure database

Create config file from template (`cp config/dbspec.yml.template config/dbspec.yml`). Change database from `postgresql` to `sqlite3` and database name from `batch_archiving` to `<as_desired>.sqlite3`.

#### Configure archive

Create config file from template (`cp config/batch_archiving.yml.template config/batch_archiving.yml`). Add your S3 credentials `access_key_id` and `secret_access_key` for target bucket `bucket`. Change `region` if necessary. If you want, change `acl` and add `bucket_sub_dir`.

#### Hop into sandbox
```
bundler exec bin/console
```

#### bin/example
Convenience functionality
- `require_relative "bin/example/schema"` for creating an example table `examples`
- `require_relative "bin/example/example"` for an example archivable model `Example`
- `require_relative "bin/example/fixture"` for a factory method `create_examples(count, start: 0, deleted: true)` for creating examples

### 2.2 testing it

#### Configure test database
Create config file from template (`cp config/dbspec_rspec.yml.template config/dbspec_rspec.yml`). Modify settings if you want.

#### Run tests
```
bundler exec rspec spec
```

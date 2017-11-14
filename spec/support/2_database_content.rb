ActiveRecord::Schema.define do
  create_table "example_hoarders", force: true do |t|
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.datetime "updated_at"
    t.string "content"
  end
end

RSpec.configure do |config|
  config.after(:each) do
    ActiveRecord::Base.connection.execute("DELETE FROM example_hoarders;")
  end
end

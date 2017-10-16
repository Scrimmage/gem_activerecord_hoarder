def create_examples(count, start: 0, deleted: true)
  (1..count).each do |n|
    Example.create(content: "example: #{n}", created_at: (n+start).hours.ago, deleted_at: Time.now)
  end
  nil
end

create_examples(3, start: 0, deleted: true)
create_examples(3, start: 0.5, deleted: true)

def create_examples(count, start: 0, deleted: true)
  (1..count).each do |n|
    Example.create(content: "example: #{n}", created_at: (n+start).hours.ago, deleted_at: Time.now)
  end
end

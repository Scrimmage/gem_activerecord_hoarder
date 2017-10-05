class ::BatchArchiving::Serializer
  def self.create_archive(batch_data)
    JSON.pretty_generate(batch_data)
  end
end

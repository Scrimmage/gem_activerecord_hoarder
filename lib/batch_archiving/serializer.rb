class ::BatchArchiving::Serializer
  def self.create_archive(batch_data)
    batch_data.to_json
  end
end

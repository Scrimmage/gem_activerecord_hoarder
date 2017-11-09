class ::ActiverecordHoarder::Serializer
  def self.create_archive(batch_data)
    batch_data.to_json
  end

  def self.extension
    :json
  end
end

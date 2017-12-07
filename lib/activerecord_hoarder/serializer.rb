class ::ActiverecordHoarder::Serializer
  def self.serialize(batch_data)
    batch_data.to_json
  end

  def self.extension
    :json
  end
end

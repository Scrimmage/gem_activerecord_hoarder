class ::ActiverecordHoarder::Storage
  class_attribute :storage, :storage_options

  def self.new(table_name, storage_override: nil, storage_options_override: {})
    self.check_configured
    storage_class = ::ActiverecordHoarder::Storages.retrieve(storage_override || storage)
    storage_class.new(table_name, storage_options.merge(storage_options_override))
  end

  def self.check_configured
    raise ::ActiverecordHoarder::StorageError.new("storage needs to be configured") unless is_configured?

  end

  def self.configure(storage:, storage_options:)
    ::ActiverecordHoarder::Storages.is_valid_storage?(storage)

    self.storage_options = storage_options
    self.storage = storage

    self
  end

  def self.is_configured?
    storage.present? && storage_options.is_a?(Hash)
  end
end

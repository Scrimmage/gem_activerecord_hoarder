class ::BatchArchiving::Storage
  class_attribute :storage, :storage_options

  def self.configure(storage:, storage_options:)
    ::BatchArchiving::Storages.is_valid_storage?(storage)

    self.storage_options = storage_options
    self.storage = storage
  end

  private

  def self.new(model_class, storage_override: nil, storage_options_override: {})
    self.check_configured
    storage_class = ::BatchArchiving::Storages.retrieve(storage_override || storage)
    storage_class.new(model_class, storage_options.merge(storage_options_override))
  end

  def self.check_configured
    raise ::BatchArchiving::StorageError.new("storage needs to be configured") unless is_configured?
  end

  def self.is_configured?
    storage.present? && storage_options.is_a?(Hash)
  end
end

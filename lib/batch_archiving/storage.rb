class ::BatchArchiving::StorageError < StandardError
end

class ::BatchArchiving::Storage
  def self.configure(storage:, storage_options:)
    check_storage(storage)
    class_attribute :storage, :storage_options

    @@storage_options = storage_options
    @@storage = storage
  end

  private

  def self.check_storage(storage_id)
    raise ::BatchArchiving::StorageError.new("unknown storage (#{storage_id}), known keys are #{::BatchArchiving::Storages.keys}") if ! ::BatchArchiving::Storages.include?(storage_id)
  end

  def self.new(model_class, storage_override: nil, storage_options_override: {})
    raise ::BatchArchiving::StorageError.new("storage needs to be configured") unless try(:storage) && try(:storage_options)
    check_storage(storage_override) unless storage_override.blank?

    storage_id = storage_override || storage
    ::BatchArchiving::Storages[storage_id].new(model_class, @@storage_options.merge(storage_options_override))
  end
end

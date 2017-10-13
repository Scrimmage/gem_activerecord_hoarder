class ::BatchArchiving::StorageError < StandardError
end

class ::BatchArchiving::Storage
  def self.configure(storage:, storage_options:)
    check_storage(storage)

    @@storage_options = storage_options
    @@storage = storage

    def self.storage_options
      @@storage_options
    end

    def self.storage
      @@storage
    end
  end

  private

  def self.check_storage(storage_id)
    raise ::BatchArchiving::StorageError.new("unknown storage (#{storage_id}), known keys are #{::BatchArchiving::Storages.keys}") if ! ::BatchArchiving::Storages.include?(storage_id)
  end

  def self.new(model, storage_override: nil, storage_options_override: {})
    raise ::BatchArchiving::StorageError.new("storage needs to be configured") unless try(:storage) and try(:storage_options)
    check_storage(storage_override) unless storage_override.blank?

    storage_id = storage_override || storage
    ::BatchArchiving::Storages[storage_id].new(model, @@storage_options.merge(storage_options_override))
  end
end

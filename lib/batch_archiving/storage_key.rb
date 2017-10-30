module BatchArchiving
  class StorageKey
    def self.from_date(date, file_extension = nil)
      key_parts = [date.year.to_s, date.month.to_s, date.iso8601]
      new(key_parts, file_extension)
    end

    def initialize(key_parts, file_extension)
      @key_parts = key_parts
      @file_extension = file_extension
    end

    def to_s
      key_without_extension = File.join(@key_parts)
      @file_extension.present? ? key_without_extension + '.' + @file_extension.to_s : key_without_extension
    end
  end
end

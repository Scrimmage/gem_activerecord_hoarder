module BatchArchiving
  module Restore
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def restore_archive_records(date)
        storage = ::BatchArchiving::Storage.new(self.table_name)
        key = ::BatchArchiving::StorageKey.from_date(date, :json)
        dataIO = storage.fetch_data(key)
        create(JSON.parse(dataIO.read))
      end
    end
  end
end

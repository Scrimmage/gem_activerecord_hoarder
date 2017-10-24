module BatchArchiving
  class BatchQuery
    SUBQUERY_DELETED_RECORDS = <<~SQL.strip_heredoc
      SELECT
        %{fields}
      FROM
        %{table_name}
      WHERE
        deleted_at IS NOT NULL
    SQL

    SUBQUERY_NON_DELETED_RECORDS = <<~SQL.strip_heredoc
      SELECT
        %{fields}
      FROM
        %{table_name}
      WHERE
        deleted_at IS NULL
    SQL

    QUERY_TEMPLATE_FOR_DATE_DELETION = <<~SQL.strip_heredoc
      DELETE FROM %{table_name} WHERE date(created_at) = '%{date}';
    SQL

    QUERY_TEMPLATE_FOR_RECORD_WITH_LIMIT = <<~SQL.strip_heredoc
      SELECT
        *
      FROM
        %{table_name}
      WHERE
        date(created_at) = (
          SELECT
            min(dates_with_deleted.creation_date)
          FROM
            (
              #{SUBQUERY_DELETED_RECORDS % {
                  fields: "date(created_at) as creation_date",
                  table_name: "%{table_name}"
              }}
            ) as dates_with_deleted
            LEFT OUTER JOIN
            (
              #{SUBQUERY_NON_DELETED_RECORDS % {
                fields: "date(created_at) as creation_date",
                table_name: "%{table_name}"
              }}
            ) as dates_with_non_deleted
            ON
              dates_with_deleted.creation_date = dates_with_non_deleted.creation_date
            WHERE
              dates_with_non_deleted.creation_date IS NULL
            AND
              created_at < '%{limit}'
        )
      ;
    SQL

    def initialize(limit, model_class)
      @limit = limit
      @model_class = model_class
    end

    def delete(date)
      QUERY_TEMPLATE_FOR_DATE_DELETION % {
        date: date,
        table_name: table_name
      }
    end

    def fetch
      QUERY_TEMPLATE_FOR_RECORD_WITH_LIMIT % {
        limit: @limit,
        table_name: table_name
      }
    end

    private

    def table_name
      @model_class.table_name
    end
  end
end

module BatchArchiving
  class BatchQuery
    QUERY_TEMPLATE_FOR_RECORD_WITH_LIMIT = <<-SQL.strip_heredoc
      SELECT *
      FROM %{table_name}
      WHERE
        created_at::date = (
      SELECT
        min(creation_date)
      FROM
        (
        SELECT
          creation_date
        FROM
          (
            SELECT
              created_at::date AS creation_date,
              CASE WHEN deleted_at IS NULL
                THEN 0
                ELSE 1
              END AS is_deleted,
              count(*)
            FROM %{table_name}
              GROUP BY
                creation_date,
                is_deleted
          ) AS state_counts
        GROUP BY
          creation_date
        HAVING
          count(*) = 1
          AND max(is_deleted) = 1
        ) AS creation_dates
      WHERE
        creation_date < '%{limit}'
      );
    SQL

    QUERY_TEMPLATE_FOR_DATE_DELETION = <<-SQL.strip_heredoc
      DELETE FROM %{table_name} WHERE created_at::date = '%{date}';
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

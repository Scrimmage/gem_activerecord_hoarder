module ActiverecordHoarder
  class BatchQuery

    SUBQUERY_CONDITION = <<~SQL.strip_heredoc
      WHERE %{condition_column} > %{outer_limit_lower}
      AND %{condition_column} < %{outer_limit_upper}
    SQL

    QUERY_TEMPLATE_FOR_DELETE = <<~SQL.strip_heredoc
      DELETE FROM %{table_name} 
      #{ SUBQUERY_CONDITION }
      ;
    SQL

    QUERY_TEMPLATE_FOR_FETCH = <<~SQL.strip_heredoc
      SELECT %{fields}
      FROM %{table_name}
      #{ SUBQUERY_CONDITION }
      ;
    SQL

    def initialize(model_class, outer_limit_lower, outer_limit_upper)
      @model_class = model_class
      @outer_limit_upper = outer_limit_upper
      @outer_limit_lower = outer_limit_lower
    end

    def delete
      QUERY_TEMPLATE_FOR_DELETE % {
        condition_column: ::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN,
        fields: fields,
        outer_limit_lower: @outer_limit_lower,
        outer_limit_upper: @outer_limit_upper,
        table_name: table_name,
      }
    end

    def fetch
      QUERY_TEMPLATE_FOR_FETCH % {
        condition_column: ::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN,
        fields: fields,
        outer_limit_lower: @outer_limit_lower,
        outer_limit_upper: @outer_limit_upper,
        table_name: table_name,
      }
    end

    private

    def fields
      "*"
    end

    def table_name
      @model_class.table_name
    end
  end
end

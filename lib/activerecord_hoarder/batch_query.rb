module ActiverecordHoarder
  class BatchQuery

    SUBQUERY_CONDITION = <<~SQL.strip_heredoc
      WHERE %{condition_column} >%{include_lower} "%{inner_lower_limit}" AND %{condition_column} <%{include_upper} "%{inner_upper_limit}"
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

    def initialize(model_class, inner_lower_limit, inner_upper_limit, include_lower: true, include_upper: true)
      @include_lower = include_lower ? "=" : ""
      @include_upper = include_upper ? "=" : ""
      @inner_lower_limit = inner_lower_limit
      @inner_upper_limit = inner_upper_limit
      @model_class = model_class
    end

    def delete
      QUERY_TEMPLATE_FOR_DELETE % {
        condition_column: ::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN,
        include_lower: @include_lower,
        include_upper: @include_upper,
        fields: fields,
        inner_lower_limit: @inner_lower_limit,
        inner_upper_limit: @inner_upper_limit,
        table_name: table_name,
      }
    end

    def fetch
      QUERY_TEMPLATE_FOR_FETCH % {
        condition_column: ::ActiverecordHoarder::Constants::TIME_LIMITING_COLUMN,
        include_lower: @include_lower,
        include_upper: @include_upper,
        fields: fields,
        inner_lower_limit: @inner_lower_limit,
        inner_upper_limit: @inner_upper_limit,
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

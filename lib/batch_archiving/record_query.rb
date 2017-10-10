::BatchArchiving::RECORD_QUERY = "
select *
from %{table_name}
where
  created_at::date = (
select
  min(creation_date)
from
  (
  select
    creation_date
  from
    (
      select
        created_at::date as creation_date,
        CASE WHEN deleted_at IS NULL
          THEN 0
          ELSE 1
        END as is_deleted,
        count(*)
      from %{table_name}
        group by
          creation_date,
          is_deleted
    ) AS state_counts
  group by
    creation_date
  having
    count(*) = 1
    and max(is_deleted) = 1
  ) as creation_dates
where
  creation_date < '%{limit}'
);
"

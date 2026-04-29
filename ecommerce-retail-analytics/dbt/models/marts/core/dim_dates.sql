{{
  config(
    materialized = 'table'
    )
}}

with generated_dates as (
    {{ get_order_date_spine() }}
)

select
    -- Integer surrogate key in YYYYMMDD format (e.g., 20231225)
    to_number(to_char(date_day, 'YYYYMMDD')) as date_key,
    date_day as date,
    year(date_day) as year,
    yearofweekiso(date_day) as iso_year,
    yearofweekiso(date_day) || '-W' || lpad(weekiso(date_day), 2, '0') as iso_year_week,
    year(date_day) || '-Q' || date_part('quarter', date_day) as year_quarter,
    to_char(date_day, 'YYYY-MM') as year_month,
    quarter(date_day) as quarter_number,
    'Q' || quarter(date_day) as quarter_name,
    month(date_day) as month,
    monthname( date_day) as month_name,
    to_char( date_day, 'Mon-YYYY') as month_year,
    week(date_day) as week,
    week(date_day) || '-' || year(date_day) as year_week,
    day(date_day) as day,
    dayofweekiso(date_day) as iso_day_of_week,
    dayname(date_day) as day_name,
    dayofweek(date_day) as day_of_week,
    case when dayname(date_day) in ('Sat', 'Sun') then true else false end as is_weekend,
    (dayofweekiso(date_day) in (6, 7)) as is_iso_weekend,
    -- Offsets (current date is 0, past dates are negative, future dates are positive)
    (date_day - current_date()) as day_offset,
    datediff('week', current_date(), date_day) as week_offset,
    datediff('month', current_date(), date_day) as month_offset,
    datediff('quarter', current_date(), date_day) as quarter_offset,
    datediff('year', current_date(), date_day) as year_offset
from generated_dates
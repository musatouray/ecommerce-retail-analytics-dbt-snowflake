-- Cohort retention fact table tracking customer retention by acquisition month
-- Use this for retention curves, cohort comparisons, and identifying improving/declining acquisition quality

with customer_cohorts as (
    -- Assign customers to cohorts based on their first order month
    select
        customer_unique_id,
        date_trunc('month', first_order_date) as cohort_month
    from {{ ref('dim_customers') }}
    where first_order_date is not null
),

customer_activity as (
    -- Get the months in which each customer was active (placed an order)
    select
        customer_unique_id,
        date_trunc('month', order_date) as activity_month
    from {{ ref('int_orders_enriched') }}
    where date_trunc('month', order_date) < date_trunc('month', current_date) -- Exclude current month to avoid partial data
    group by 1, 2
),

cohort_activity as (
    -- Join cohorts with activity to calculate active customers per cohort and period
    select
        cc.cohort_month,
        ca.activity_month,
        datediff('month', cc.cohort_month, ca.activity_month) as period_number,
        count(distinct ca.customer_unique_id) as active_customers
    from customer_cohorts cc
    left join customer_activity ca using (customer_unique_id)
    where ca.activity_month is not null and datediff('month', cc.cohort_month, ca.activity_month) >= 0 -- Only consider activity after cohort month
    group by 1, 2, 3
),

cohort_sizes as (
    -- Calculate the size of each cohort
    select
        cohort_month,
        count(distinct customer_unique_id) as cohort_size
    from customer_cohorts
    group by 1
),

retention_metrics as (
    -- Calculate retention and churn rates for each cohort and period
    select
        ca.cohort_month,
        ca.period_number,
        ca.active_customers,
        cs.cohort_size,
        case when cs.cohort_size > 0 then (active_customers::float / cs.cohort_size) * 100 else 0 end as retention_rate
    from cohort_activity ca
    left join cohort_sizes cs using (cohort_month)
)

select
    {{ dbt_utils.generate_surrogate_key(['cohort_month', 'period_number']) }} as cohort_retention_key,
    -- FK to dim_cohorts
    {{ dbt_utils.generate_surrogate_key(['cohort_month']) }} as cohort_key,
    cohort_month,
    period_number,
    active_customers,
    cohort_size,
    round(retention_rate, 2) as retention_rate,
    round(100 - retention_rate, 2) as churn_rate,

    -- Metadata
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from retention_metrics
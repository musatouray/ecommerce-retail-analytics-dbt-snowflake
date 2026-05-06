-- Customer Lifetime Value fact table with historical and predicted CLV                                                                           
-- Use this for customer valuation, acquisition ROI, and high-value customer identification

with customer_base as (
    -- Get customer-level metrics from dim_customers to use in CLV calculation
    select
        customer_unique_id,
        cohort_key,
        total_orders,
        total_revenue as historical_clv,
        average_order_value
    from {{ ref('dim_customers') }}
    where total_orders > 0 -- Focus on customers with at least 1 order
),

cohort_benchmarks as (
    -- Calculate average CLV per cohort from dim_cohorts to use as benchmarks for customer segmentation
    select
        cohort_key,
        avg_customer_value as cohort_avg_clv
    from {{ ref('dim_cohorts') }}
),

clv_calculations as (
    -- Calculate historical and predicted CLV for each customer
    select
        cb.customer_unique_id,
        cb.cohort_key,
        cb.total_orders,
        cb.average_order_value,
        cb.historical_clv,
        cbm.cohort_avg_clv as expected_ltv,
        -- Predicted: at minimum, expect them to reach cohort average
        greatest(cb.historical_clv, cbm.cohort_avg_clv) as predicted_ltv,
        -- Value vs expectation: positive = above average, negative = below average
        cb.historical_clv - cbm.cohort_avg_clv as value_vs_cohort,
        -- CLV score for segmentation (use predicted as the basis)
        greatest(cb.historical_clv, cbm.cohort_avg_clv) as clv_score
    from customer_base cb
    left join cohort_benchmarks cbm using (cohort_key)
),

clv_segments as (
    -- Segment customers based on CLV score (higher = better)
    select
        *,
        ntile(10) over (order by clv_score asc) as clv_decile,
        case
            when ntile(10) over (order by clv_score asc) = 10 then 'Platinum'
            when ntile(10) over (order by clv_score asc) >= 8 then 'Gold'
            when ntile(10) over (order by clv_score asc) >= 5 then 'Silver'
            else 'Bronze'
        end as clv_segment
    from clv_calculations
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id']) }} as clv_key,
        customer_unique_id,
        cohort_key,
        total_orders,
        average_order_value,
        historical_clv,
        expected_ltv,
        predicted_ltv,
        value_vs_cohort,
        clv_score,
        clv_decile,
        clv_segment,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from clv_segments
)

select * from final
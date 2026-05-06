-- Churn risk fact table identifying customers at risk of churning or already churned
-- Use this for retention campaigns, win-back targeting, and customer health monitoring

with reference_date as (
    select 
        max(order_date) as max_date
     from {{ ref('int_orders_enriched') }}
),

customer_base as (
    -- Get customer-level metrics from dim_customers to use in CLV calculation
    select
        customer_unique_id,
        cohort_key,
        last_order_date,
        total_orders,
        total_revenue,
        average_rating
    from {{ ref('dim_customers') }}
    where total_orders > 0 -- Remove customers who have not made any purchases (prospects)
),

churn_metrics as (
    select
        cb.customer_unique_id,
        cb.cohort_key,
        cb.last_order_date,
        cb.total_orders,
        cb.total_revenue,
        cb.average_rating,
        datediff(day, cb.last_order_date, r.max_date) as days_since_last_order,
        (cb.total_orders = 1) as is_single_purchaser,
        -- Simple churn risk score based on recency and engagement
        case
            when datediff(day, cb.last_order_date, r.max_date) > 90 then 'Churned'
            when datediff(day, cb.last_order_date, r.max_date) between 60 and 90 then 'At Risk'
            when datediff(day, cb.last_order_date, r.max_date) between 30 and 60 then 'Cooling'
            else 'Active'
        end as churn_status,

        -- Customer satisfaction segment based on reviews
        case
            when cb.average_rating is null then 'unknown'
            when cb.average_rating >= {{ var('customer_promoter_threshold') }} then 'promoter'
            when cb.average_rating >= {{ var('customer_neutral_threshold') }} then 'neutral'
            else 'detractor'
        end as customer_nps_segment
    from customer_base cb
    cross join reference_date r
),

churn_risk_score as (
    select
        customer_unique_id,
        cohort_key,
        last_order_date,
        total_orders,
        total_revenue,
        average_rating,
        days_since_last_order,
        is_single_purchaser,
        churn_status,
        customer_nps_segment,
        -- Additive churn risk score (0-100, higher = more at risk)
        (
            -- Dormancy contributes 0-40 points
            case
                when churn_status = 'Churned' then 40
                when churn_status = 'At Risk' then 30
                when churn_status = 'Cooling' then 15
                else 0
            end
            -- Single purchaser adds 25 points (high churn risk)
            + case when is_single_purchaser then 25 else 0 end
            -- Detractor/unknown NPS adds risk
            + case
                when customer_nps_segment = 'detractor' then 20
                when customer_nps_segment = 'unknown' then 10
                else 0
              end
            -- Low value customer adds 15 points
            + case when total_revenue < 100 then 15 else 0 end
        ) as churn_risk_score
    from churn_metrics
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id']) }} as churn_risk_key,
        customer_unique_id,
        cohort_key,
        last_order_date,
        total_orders,
        total_revenue,
        average_rating,
        days_since_last_order,
        is_single_purchaser,
        churn_status,
        customer_nps_segment,
        churn_risk_score,
        -- Risk segment based on composite score
        case
            when churn_risk_score >= 75 then 'Critical'
            when churn_risk_score >= 50 then 'High'
            when churn_risk_score >= 25 then 'Medium'
            else 'Low'
        end as churn_risk_segment,

        -- Metadata
        current_timestamp as created_at,
        current_timestamp as updated_at
    from churn_risk_score
)

select * from final
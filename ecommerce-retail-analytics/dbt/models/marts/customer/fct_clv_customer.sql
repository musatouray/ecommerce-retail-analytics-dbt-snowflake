-- Customer Lifetime Value fact table with probabilistic CLV prediction                                                                     
-- Uses exponential decay model based on purchase recency and frequency                                                                     
-- Model: P(purchase) = e^(-λt) where λ = purchase_rate, t = days_since_last_order

with reference_date as (
    -- Use max order date to calculate recency
    select max(order_date) as analysis_date 
    from {{ ref('int_orders_enriched') }}
),

customer_base as (
    -- Get customer-level metrics from dim_customers to use in CLV calculation
    select
        c.customer_unique_id,
        c.cohort_key,
        c.first_order_date,
        c.last_order_date,
        c.total_orders,
        c.total_revenue as historical_clv,
        c.average_order_value,
        c.customer_tenure_days,
        datediff(day, c.last_order_date, rd.analysis_date) as days_since_last_order,
        datediff(day, c.first_order_date, rd.analysis_date) as customer_age_days -- Customer lifespan in days
    from {{ ref('dim_customers') }} c
    cross join reference_date rd
    where total_orders > 0 -- Focus on customers with at least 1 order
),

global_averages as (
    -- Calculate global averages as ultimate fallback
    select
        avg(case when total_orders > 1 then customer_tenure_days / (total_orders - 1) end) as global_avg_days_between_purchases,
        avg(average_order_value) as global_avg_order_value
    from customer_base
),

cohort_averages as (
    -- Calculate cohort-level averages for customers with insufficient data
    select
        cohort_key,
        avg(case when total_orders > 1 then customer_tenure_days / (total_orders - 1) end) as cohort_avg_days_between_purchases,
        avg(average_order_value) as cohort_avg_order_value
    from customer_base
    group by cohort_key
),

purchase_metrics as (
    -- Calculate purchase rate (λ) for each customer using their own data, cohort averages, or global fallback
    select
        cb.*,
        coalesce(ca.cohort_avg_days_between_purchases, ga.global_avg_days_between_purchases) as cohort_avg_days_between_purchases,
        coalesce(ca.cohort_avg_order_value, ga.global_avg_order_value) as cohort_avg_order_value,

        -- Average days between purchases: customer > cohort > global
        case
            when cb.total_orders > 1 then cb.customer_tenure_days / (cb.total_orders - 1)
            else coalesce(ca.cohort_avg_days_between_purchases, ga.global_avg_days_between_purchases)
        end as avg_days_between_purchases,

        -- Purchase rate λ = 1 / avg_days_between_purchases (higher means more frequent)
        case
            when cb.total_orders > 1 then (cb.total_orders - 1) / nullif(cb.customer_tenure_days, 0)
            else 1.0 / nullif(coalesce(ca.cohort_avg_days_between_purchases, ga.global_avg_days_between_purchases), 0)
        end as purchase_rate_lambda
    from customer_base cb
    left join cohort_averages ca using (cohort_key)
    cross join global_averages ga
),

clv_predictions as (
    select
        pm.*,

        -- Prediction horizon: 365 days (1 year)
        {{ var ('clv_prediction_horizon_days', 365) }} as prediction_horizon_days,

        -- Purchase probability using exponential decay: P = e^(-λt)                                                                        
        -- Ranges from 1 (just purchased) to ~0 (long time ago)
        exp(-1.0 *purchase_rate_lambda * days_since_last_order) as purchase_probability,
        
        -- Expected purchases in horizon = probability × (horizon / avg_purchase_cycle)                                                     
        -- Capped at reasonable maximum based on historical frequency
        least(
            exp(-1.0 * purchase_rate_lambda * days_since_last_order) * 
            ({{ var ('clv_prediction_horizon_days', 365) }} / nullif(avg_days_between_purchases, 0)),
            -- Cap at 2x historical annual rate to avoid over-prediction
            total_orders * 2.0 * ({{ var('clv_prediction_horizon_days', 365) }} / nullif(customer_age_days, 0))
        ) as expected_future_purchases,

        -- Predicted future revenue
        least(
            exp(-1.0 * purchase_rate_lambda * days_since_last_order) * 
            ({{ var ('clv_prediction_horizon_days', 365) }} / nullif(avg_days_between_purchases, 0)),
            total_orders * 2.0 * ({{ var('clv_prediction_horizon_days', 365) }} / nullif(customer_age_days, 0))
        ) * coalesce(average_order_value, cohort_avg_order_value) as predicted_future_value
    from purchase_metrics pm
),

clv_scored as (
    select
        cp.*,

        -- Combine historical CLV and predicted future value into a single CLV score
        historical_clv + coalesce(predicted_future_value, 0) as predicted_clv,

        -- CLV decile score (1-10, where 10 = highest value)
         ntile(10) over (order by historical_clv + coalesce(predicted_future_value, 0) asc) as clv_decile
    from clv_predictions cp
),

clv_segments as (
    -- Define CLV segments based on deciles
    select
        *,
        case                                                                                                                                
            when clv_decile = 10 then 'Platinum'                                                                                            
            when clv_decile >= 8 then 'Gold'                                                                                                
            when clv_decile >= 5 then 'Silver'                                                                                              
            else 'Bronze'                                                                                                                   
        end as clv_segment
    from clv_scored
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id']) }} as clv_key,
        customer_unique_id,
        cohort_key,

        -- Historical metrics
        total_orders,
        average_order_value,
        historical_clv,
        customer_age_days,
        days_since_last_order,

        -- CLV prediction metrics
        round(expected_future_purchases, 2) as expected_future_purchases,
        round(predicted_future_value, 2) as predicted_future_value,
        round(predicted_clv, 2) as predicted_clv,

        -- Model parameters for transparency
        round(avg_days_between_purchases, 2) as avg_days_between_purchases,
        round(purchase_rate_lambda, 6) as purchase_rate_lambda,
        round(purchase_probability, 4) as purchase_probability,

        -- CLV segment
        clv_decile,
        clv_segment,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from clv_segments
)

select * from final
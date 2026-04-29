with customers as (
    select * from {{ ref('stg_ecommerce__customers') }}
),

orders as (
    select * from {{ ref('int_orders_enriched') }}
),

-- Aggregate orders at the customer level grain
customer_orders as (
    select
        customer_unique_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(distinct order_id) as total_orders,
        sum(total_payment_value) as total_revenue,
        sum(review_count) as total_reviews,
        -- Weighted average: sum of all scores / total number of reviews
        sum(total_score) / nullif(sum(review_count), 0) as average_rating
    from orders
    group by customer_unique_id
),

-- Dedupe customers to unique customer level (take most recent address)
deduped_customers as (
    select
        customer_unique_id,
        first_value(zip_code) over (partition by customer_unique_id order by customer_id desc) as zip_code,
        first_value(city) over (partition by customer_unique_id order by customer_id desc) as city,
        first_value(state) over (partition by customer_unique_id order by customer_id desc) as state
    from customers
    qualify row_number() over (partition by customer_unique_id order by customer_id desc) = 1
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['dc.customer_unique_id']) }} as customer_key,
        dc.customer_unique_id,
        dc.zip_code,
        dc.city,
        dc.state,
        co.first_order_date,
        co.last_order_date,
        coalesce(co.total_orders, 0) as total_orders,
        coalesce(co.total_revenue, 0) as total_revenue,
        co.total_revenue / nullif(co.total_orders, 0) as average_order_value,
        co.total_reviews,
        co.average_rating,
        datediff(day, co.last_order_date, current_date) as days_since_last_order,
        datediff(day, co.first_order_date, co.last_order_date) as customer_tenure_days,

        -- Customer purchase segment
        case
            when co.total_orders is null then 'prospect'
            when co.total_orders = 1 then 'new'
            else 'returning'
        end as customer_segment,

        -- Customer value segment based on revenue
        case
            when co.total_revenue is null then 'unknown'
            when co.total_revenue >= {{ var('customer_high_value_threshold') }} then 'high_value'
            when co.total_revenue >= {{ var('customer_medium_value_threshold') }} then 'medium_value'
            else 'low_value'
        end as customer_value_segment,

        -- Customer satisfaction segment based on average rating
        case
            when co.average_rating is null then 'unknown'
            when co.average_rating >= {{ var('customer_promoter_threshold') }} then 'promoter'
            when co.average_rating >= {{ var('customer_neutral_threshold') }} then 'neutral'
            else 'detractor'
        end as customer_satisfaction_segment,

        -- Active customer flag
        case
            when datediff(day, co.last_order_date, current_date) <= {{ var('customer_active_days_threshold') }} then TRUE
            else FALSE
        end as is_active,

        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from deduped_customers dc
    left join customer_orders co using (customer_unique_id)
)

select * from final

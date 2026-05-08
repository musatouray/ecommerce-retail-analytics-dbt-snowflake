-- Order funnel fact table tracking conversion rates through order lifecycle stages
-- Use this for funnel visualization, drop-off analysis, and cycle time monitoring

with orders as (
    select *
    from {{ ref('int_orders_enriched') }}
),

funnel_calculations as (
    select
        -- Grain: Monthly trends
        date_Trunc('month', order_date) as funnel_month,

        -- Funnel stage counts. Snowflake count(col) ignores nulls automatically, so we can use it to count how many orders reached each stage.
        count(*) as orders_placed,
        count(order_approved_at) as orders_approved,
        count(delivered_carrier_date) as orders_shipped,
        count(delivered_customer_date) as orders_delivered,
        count(case when review_count > 0 then 1 end) as orders_reviewed,

        -- Funnel exit counts
        sum(case when order_status = 'canceled' then 1 else 0 end) as orders_canceled,
        sum(case when order_status = 'unavailable' then 1 else 0 end) as orders_unavailable,

        -- Order cycle times in days (Using seconds and dividing by 86400 to get days, for decimal days precision)
        avg(datediff(second, order_date, order_approved_at) / 86400.0) as avg_days_to_approval,
        avg(datediff(second, order_approved_at, delivered_carrier_date) / 86400.0) as avg_days_to_ship,
        avg(datediff(second, delivered_carrier_date, delivered_customer_date) / 86400.0) as avg_days_in_transit,
        avg(datediff(second, order_date, delivered_customer_date) / 86400.0) as avg_days_to_delivery
    
    from orders
    group by 1
),

final as (
    select
        -- Generate surrogate key
        {{ dbt_utils.generate_surrogate_key(['funnel_month']) }} as funnel_key,
        to_number(to_char(funnel_month, 'YYYYMMDD')) as date_key,
        funnel_month as month_date,
        to_char(funnel_month, 'Mon-YYYY') as month_year,
        orders_placed,
        orders_approved,
        orders_shipped,
        orders_delivered,
        orders_reviewed,
        orders_canceled,
        orders_unavailable,

        -- Drop-off counts
        orders_placed - orders_approved as dropped_before_approval,
        orders_approved - orders_shipped as dropped_before_shipping,
        orders_shipped - orders_delivered as dropped_before_delivery,
        orders_delivered - orders_reviewed as dropped_before_review,

        -- Conversion rates
        round(orders_approved * 100.0 / nullif(orders_placed, 0), 2) as placed_to_approved_pct,
        round(orders_shipped * 100.0 / nullif(orders_approved, 0), 2) as approved_to_shipped_pct,
        round(orders_delivered * 100.0 / nullif(orders_shipped, 0), 2) as shipped_to_delivered_pct,
        round(orders_reviewed * 100.0 / nullif(orders_delivered, 0), 2) as delivered_to_reviewed_pct,

        -- Overall conversion rates
        round(orders_delivered * 100.0 / nullif(orders_placed, 0), 2) as overall_delivery_rate,
        round(orders_reviewed * 100.0 / nullif(orders_placed, 0), 2) as overall_review_rate,

        -- Cancellation & unavailability rates
        round(orders_canceled * 100.0 / nullif(orders_placed, 0), 2) as cancellation_rate,
        round(orders_unavailable * 100.0 / nullif(orders_placed, 0), 2) as unavailability_rate,

        -- Cycle times
        round(avg_days_to_approval, 1) as avg_days_to_approval,
        round(avg_days_to_ship, 1) as avg_days_to_ship,
        round(avg_days_in_transit, 1) as avg_days_in_transit,
        round(avg_days_to_delivery, 1) as avg_days_to_delivery,

        -- Metadata
        current_timestamp as created_at,
        current_timestamp as updated_at
    from funnel_calculations
)

select * from final
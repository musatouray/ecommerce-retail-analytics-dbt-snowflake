-- Fact table for orders at order grain (one row per order)
-- Use this for order-level analytics: revenue trends, AOV, customer behavior
-- Uses role-playing dimensions for multiple date contexts

with orders as (
    select *
    from {{ ref('int_orders_enriched') }}
),

dim_customers as (
    select customer_key, customer_unique_id
    from {{ ref('dim_customers') }}
),

dim_dates as (
    select date_key, date
    from {{ ref('dim_dates') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_key,

        -- Natural key
        o.order_id,

        -- Dimension keys
        c.customer_key,

        -- Role-playing date dimension keys
        d_order.date_key as order_date_key,
        d_approval.date_key as approval_date_key,
        d_delivery.date_key as delivery_date_key,
        d_estimated.date_key as estimated_delivery_date_key,

        -- Order attributes
        o.order_status,

        -- Delivery metrics
        datediff(day, o.order_date, o.delivered_customer_date) as delivery_days,
        datediff(day, o.order_approved_at, o.delivered_customer_date) as fulfillment_days,
        datediff(day, o.delivered_carrier_date, o.delivered_customer_date) as shipping_transit_days,
        case
            when o.delivered_customer_date <= o.estimated_delivery_date then true
            else false
        end as is_on_time_delivery,

        -- Order metrics
        o.total_price,
        o.total_freight_value,
        o.total_price + o.total_freight_value as gross_order_value,
        o.payment_count,
        o.total_payment_value,

        -- Review metrics
        o.review_count,
        o.avg_score as review_score,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from orders o
    left join dim_customers c on o.customer_unique_id = c.customer_unique_id
    -- Role-playing date dimensions
    left join dim_dates d_order on o.order_date = d_order.date
    left join dim_dates d_approval on o.order_approved_at::date = d_approval.date
    left join dim_dates d_delivery on o.delivered_customer_date::date = d_delivery.date
    left join dim_dates d_estimated on o.estimated_delivery_date::date = d_estimated.date
)

select * from final

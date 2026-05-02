-- Fact table for order items at line-item grain (one row per order item)
-- Use this for product/seller analytics: category performance, seller metrics, basket analysis
-- Uses role-playing dimensions for date contexts

with order_items as (
    select *
    from {{ ref('int_order_items_enriched') }}
),

orders as (
    select order_id, customer_unique_id
    from {{ ref('int_orders_enriched') }}
),

dim_customers as (
    select customer_key, customer_unique_id
    from {{ ref('dim_customers') }}
),

dim_products as (
    select product_key, product_id
    from {{ ref('dim_products') }}
),

dim_sellers as (
    select seller_key, seller_id
    from {{ ref('dim_sellers') }}
),

dim_dates as (
    select date_key, date
    from {{ ref('dim_dates') }}
),

final as (
    select
        -- Surrogate key (composite grain)
        {{ dbt_utils.generate_surrogate_key(['oi.order_id', 'oi.order_item_id']) }} as order_item_key,

        -- Natural keys
        oi.order_id,
        oi.order_item_id,

        -- Dimension keys
        c.customer_key,
        p.product_key,
        s.seller_key,

        -- Role-playing date dimension keys
        d_order.date_key as order_date_key,
        d_delivery.date_key as delivery_date_key,

        -- Order attributes
        oi.order_status,

        -- Product attributes (for quick access without joining dim)
        oi.product_category_english as product_category,

        -- Item metrics
        oi.price as item_price,
        oi.freight_value as item_freight,
        oi.price + oi.freight_value as item_total,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from order_items oi
    left join orders o on oi.order_id = o.order_id
    left join dim_customers c on o.customer_unique_id = c.customer_unique_id
    left join dim_products p on oi.product_id = p.product_id
    left join dim_sellers s on oi.seller_id = s.seller_id
    -- Role-playing date dimensions
    left join dim_dates d_order on oi.order_date = d_order.date
    left join dim_dates d_delivery on oi.delivered_customer_date::date = d_delivery.date
)

select * from final

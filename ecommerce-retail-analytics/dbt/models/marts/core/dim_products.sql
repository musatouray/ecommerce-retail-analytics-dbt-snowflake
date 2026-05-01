with products as (
    select *
    from {{ ref('stg_ecommerce__products') }}
),

orders as (
    select *
    from {{ ref('int_orders_enriched') }}
),
order_items as (
    select *
    from {{ ref('int_order_items_enriched') }}
),

products_orders as (
    select
        oi.product_id,
        min(oi.order_date) as first_order_date,
        max(oi.order_date) as last_order_date,
        count(distinct oi.order_id) as total_orders,
        count(*) as total_units_sold,
        sum(oi.price + oi.freight_value) as total_revenue,
        sum(case when oi.order_status = 'canceled' then 1 else 0 end) as canceled_orders,
        count(distinct case when oi.order_status = 'canceled' then oi.order_id end)::float / nullif(count(distinct oi.order_id), 0) * 100 as canceled_rate,
        sum(o.review_count) as total_reviews,
        sum(o.total_score) / nullif(sum(o.review_count), 0) as average_rating
    from order_items oi
    left join orders o using (order_id)
    group by product_id
),

final as (
    select
        -- Generate surrogate key for product dimension
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        p.product_id,
        p.product_category_english as product_category,

        -- Product sales attributes
        po.first_order_date,
        po.last_order_date,
        po.total_orders,
        po.total_units_sold,
        po.canceled_orders,
        po.canceled_rate,
        po.total_revenue,

        -- Product review attributes
        po.total_reviews,
        po.average_rating,
        
        -- Product segmentation based on revenue
        case
            when po.total_revenue is null then 'no_sales'
            when po.total_revenue >= {{ var('platinum_value_threshold') }} then 'platinum'
            when po.total_revenue >= {{ var('gold_value_threshold') }} then 'gold'
            when po.total_revenue >= {{ var('silver_value_threshold') }} then 'silver'
            else 'bronze'
        end as performance_segment,

        -- Product attributes
        p.name_length,
        p.description_length,
        p.photos_qty,
        p.weight_g,
        p.length_cm,
        p.height_cm,
        p.width_cm,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from products p
    left join products_orders po using (product_id)
)

select * from final

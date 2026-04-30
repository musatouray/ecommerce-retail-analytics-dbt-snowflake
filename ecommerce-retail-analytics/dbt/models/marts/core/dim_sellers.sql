with sellers as (
    select * from {{ ref('stg_ecommerce__sellers') }}
),

geolocation as (
    select * from {{ ref('stg_ecommerce__geolocation') }}
),

seller_orders as (
    select 
        seller_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(distinct order_id) as total_orders,
        count(*) as total_items_sold,
        sum(price + freight_value) as total_revenue,
        avg(case when order_status = 'delivered' then datediff(day, order_date, delivered_customer_date::date) end) as average_delivery_days,
        avg(case when order_status = 'delivered' then datediff(day, delivered_carrier_date::date, delivered_customer_date::date) end) as average_shipping_transit_days,
        avg(case when order_status = 'delivered' then datediff(day, order_approved_at::date, delivered_customer_date::date) end) as average_fulfillment_days,
        sum(case when order_status = 'delivered' then 1 else 0 end) as successful_orders,
        sum(case when order_status = 'delivered' then price + freight_value else 0 end) as successful_revenue,
        count(distinct case when order_status = 'delivered' then order_id end)::float / nullif(count(distinct order_id), 0) * 100 as success_rate,
        sum(case when order_status = 'delivered' then price + freight_value else 0 end) / nullif(sum(price + freight_value), 0) * 100 as revenue_success_rate
    from {{ ref('int_order_items_enriched') }}
    group by seller_id
),

seller_primary_category as (
    select
        seller_id,
        product_category_english,
        count(*) as items_sold
    from {{ ref('int_order_items_enriched') }}
    where product_category_english is not null
    group by seller_id, product_category_english
    qualify row_number() over (partition by seller_id order by count(*) desc, max(order_date) desc, product_category_english) = 1
),

final as (
    select
        -- Generate surrogate key for seller dimension
        {{ dbt_utils.generate_surrogate_key(['s.seller_id']) }} as seller_key,
        s.seller_id,

        -- Location attributes
        s.zip_code,
        s.city,
        s.state,
        g.latitude,
        g.longitude,

        -- Orders activity attributes
        so.first_order_date,
        so.last_order_date,
        datediff(day, so.first_order_date, so.last_order_date) as seller_tenure_days,
        datediff(day, so.last_order_date, current_date) as days_since_last_sale,
        so.average_delivery_days,
        so.average_shipping_transit_days,
        so.average_fulfillment_days,

        -- Primary product category
        coalesce(spc.product_category_english, 'Unknown') as primary_product_category,

        -- Active seller flag
        so.last_order_date >= dateadd(day, -{{ var('active_days_threshold') }}, current_date) as is_active,
        
        -- Performance metrics
        coalesce(so.total_orders, 0) as total_orders,
        coalesce(so.total_items_sold, 0) as total_items_sold,
        coalesce(so.total_revenue, 0) as total_revenue,
        coalesce(so.successful_orders, 0) as successful_orders,
        coalesce(so.successful_revenue, 0) as successful_revenue,
        coalesce(so.success_rate, 0) as sale_success_rate,
        coalesce(so.revenue_success_rate, 0) as revenue_success_rate,

        -- Seller performance segment
        case
            when so.total_revenue is null then 'inactive'
            when so.total_revenue >= {{ var('seller_platinum_value_threshold') }} then 'platinum'
            when so.total_revenue >= {{ var('seller_gold_value_threshold') }} then 'gold'
            when so.total_revenue >= {{ var('seller_silver_value_threshold') }} then 'silver'
            else 'bronze'
        end as performance_segment
    from sellers s
    left join geolocation g using (zip_code)
    left join seller_orders so using (seller_id)
    left join seller_primary_category spc using (seller_id)
)

select * from final
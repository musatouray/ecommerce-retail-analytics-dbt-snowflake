-- Geographic performance fact table aggregated by customer state and month
-- Use this for regional trends, market analysis, and geographic expansion insights

with orders as (
    select
        order_id,
        order_date,
        to_char(order_date, 'YYYY-MM') as year_month,
        state,
        city,
        order_status,
        total_price,
        total_freight_value,
        total_payment_value,
        review_count,
        avg_score
    from {{ ref('int_orders_enriched') }}
),

dim_dates as (
    select date_key, date
    from {{ ref('dim_dates') }}
),

geo_monthly as (
    select
        state,
        year_month,
        min(order_date) as month_start_date,
        count(distinct order_id) as total_orders,
        count(distinct case when order_status = 'delivered' then order_id end) as delivered_orders,
        count(distinct case when order_status = 'canceled' then order_id end) as canceled_orders,
        count(distinct city) as unique_cities,
        sum(total_price) as total_price,
        sum(total_freight_value) as total_freight,
        sum(total_price + total_freight_value) as total_revenue,
        sum(total_payment_value) as total_payment_value,
        avg(total_payment_value) as average_order_value,
        sum(review_count) as total_reviews,
        avg(avg_score) as average_review_score
    from orders
    group by state, year_month
),

final as (
    select
        -- Geographic grain keys
        gm.state,
        gm.year_month,
        d.date_key as month_date_key,

        -- Order metrics
        gm.total_orders,
        gm.delivered_orders,
        gm.canceled_orders,
        gm.unique_cities,

        -- Revenue metrics
        gm.total_price,
        gm.total_freight,
        gm.total_revenue,
        gm.total_payment_value,
        gm.average_order_value,

        -- Review metrics
        gm.total_reviews,
        gm.average_review_score,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from geo_monthly gm
    left join dim_dates d on gm.month_start_date = d.date
)

select * from final

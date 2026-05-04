-- Daily revenue fact table aggregated at date grain
-- Use this for revenue trends, daily performance, and time-series analysis

with orders as (
    select *
    from {{ ref('int_orders_enriched') }}
),

dim_dates as (
    select date_key, date
    from {{ ref('dim_dates') }}
),

daily_aggregates as (
    select
        o.order_date,
        count(distinct o.order_id) as total_orders,
        count(distinct case when o.order_status = 'delivered' then o.order_id end) as delivered_orders,
        count(distinct case when o.order_status = 'canceled' then o.order_id end) as canceled_orders,
        sum(o.total_price) as total_price,
        sum(o.total_freight_value) as total_freight,
        sum(o.total_price + o.total_freight_value) as gross_revenue,
        sum(o.total_payment_value) as total_payment_value,
        avg(o.total_payment_value) as average_order_value,
        sum(o.review_count) as total_reviews,
        avg(o.avg_score) as average_review_score
    from orders o
    group by o.order_date
),

final as (
    select
        -- Date key
        d.date_key,

        -- Metrics
        da.total_orders,
        da.delivered_orders,
        da.canceled_orders,
        da.total_price,
        da.total_freight,
        da.gross_revenue,
        da.total_payment_value,
        da.average_order_value,
        da.total_reviews,
        da.average_review_score,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from daily_aggregates da
    left join dim_dates d on da.order_date = d.date
)

select * from final

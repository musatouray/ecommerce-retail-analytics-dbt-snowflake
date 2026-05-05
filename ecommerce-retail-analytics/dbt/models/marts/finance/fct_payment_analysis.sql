-- Payment analysis fact table aggregated by payment type and month
-- Use this for payment method performance, installment analysis, and payment trends

with payments as (
    select *
    from {{ ref('stg_ecommerce__order_payments') }}
),

orders as (
    select order_id, order_date
    from {{ ref('stg_ecommerce__orders') }}
),

dim_dates as (
    select date_key, date
    from {{ ref('dim_dates') }}
),

payments_enriched as (
    select
        p.order_id,
        p.payment_type,
        p.payment_installments,
        p.payment_value,
        o.order_date,
        to_char(o.order_date, 'YYYY-MM') as year_month
    from payments p
    left join orders o using (order_id)
),

monthly_aggregates as (
    select
        payment_type,
        year_month,
        min(order_date) as month_start_date,
        count(*) as total_transactions,
        count(distinct order_id) as total_orders,
        sum(payment_value) as total_payment_value,
        avg(payment_value) as average_payment_value,
        avg(payment_installments) as average_installments,
        max(payment_installments) as max_installments
    from payments_enriched
    group by payment_type, year_month
),

final as (
    select
        -- Grain keys
        ma.payment_type,
        ma.year_month,

        -- Date key (first day of month)
        d.date_key as month_date_key,

        -- Metrics
        ma.total_transactions,
        ma.total_orders,
        ma.total_payment_value,
        ma.average_payment_value,
        ma.average_installments,
        ma.max_installments,

        -- Derived metrics
        ma.total_payment_value / nullif(ma.total_orders, 0) as revenue_per_order,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from monthly_aggregates ma
    left join dim_dates d on ma.month_start_date = d.date
)

select * from final

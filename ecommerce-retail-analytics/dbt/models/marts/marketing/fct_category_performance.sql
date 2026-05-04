-- Category performance fact table aggregated by product category and month
-- Use this for category trends, product mix analysis, and merchandising insights

with order_items as (
    select
        order_id,
        product_category_english,
        order_date,
        to_char(order_date, 'YYYY-MM') as year_month,
        price,
        freight_value
    from {{ ref('int_order_items_enriched') }}

),

dim_dates as (
    select 
        date_key, 
        date
    from {{ ref('dim_dates') }}
),

category_monthly as (

    select
        product_category_english as product_category,
        year_month,
        min(order_date) as month_start_date,
        count(*) as total_items_sold,
        count( distinct order_id) as total_orders,
        sum(price) as total_price,
        sum(freight_value) as total_freight,
        sum(price + freight_value) as total_revenue,
        avg(price + freight_value) as average_item_value

    from order_items
    group by product_category_english, year_month

),

final as (

    select
        -- Category grain keys
        cm.product_category,
        cm.year_month,
        d.date_key as month_date_key,

        -- Category performance metrics
        cm.total_items_sold,
        cm.total_orders,
        cm.total_price,
        cm.total_freight,
        cm.total_revenue,
        cm.average_item_value,

        --Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at

    from category_monthly cm
    left join dim_dates d on cm.month_start_date = d.date

)

select * from final
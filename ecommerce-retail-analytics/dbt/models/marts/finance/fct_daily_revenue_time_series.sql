-- Daily revenue fact table aggregated at date grain
-- Use this for revenue trends, daily performance, and time-series analysis
with orders as (
    select *
    from {{ ref('int_orders_enriched') }}
),

dim_dates as (
    select 
        date_key, 
        date,
        year,
        quarter_number,
        month,
        iso_year_week
    from {{ ref('dim_dates') }}
),

daily_orders_aggregates as (
    select
        order_date,
        count(distinct order_id) as total_orders,
        count(distinct case when order_status = 'delivered' then order_id end) as delivered_orders,
        count(distinct case when order_status = 'canceled' then order_id end) as canceled_orders,
        sum(total_price) as total_revenue,
        sum(total_freight_value) as total_freight,
        sum(total_price + total_freight_value) as gross_revenue,
        sum(review_count) as total_reviews,
        sum(total_score) / nullif(sum(review_count), 0) as avg_review_score
    from orders
    group by order_date
),

daily_base as (
    select
        d.date_key,
        d.date,
        d.year,
        d.quarter_number,
        d.month,
        d.iso_year_week,
        -- Use COALESCE to replace NULLs with 0 for days without orders
        coalesce(da.total_orders, 0) as total_orders,
        coalesce(da.delivered_orders, 0) as delivered_orders,
        coalesce(da.canceled_orders, 0) as canceled_orders,
        coalesce(da.total_revenue, 0) as total_revenue,
        coalesce(da.total_freight, 0) as total_freight,
        coalesce(da.gross_revenue, 0) as gross_revenue,
        coalesce(da.total_reviews, 0) as total_reviews,
        da.total_revenue / nullif(da.total_orders, 0) as average_order_value,  -- Keep NULL when no orders
        da.avg_review_score  -- Keep NULL when no reviews
    from dim_dates d
    left join daily_orders_aggregates da on d.date = da.order_date
),

prior_periods as (
    select
       curr.*,

        -- Prior week metrics
        prev_week.total_orders as orders_prev_week,
        prev_week.total_revenue as revenue_prev_week,

        -- Prior month metrics
        prev_month.total_orders as orders_prev_month,
        prev_month.total_revenue as revenue_prev_month,

        -- Prior year metrics
        prev_year.total_orders as orders_prev_year,
        prev_year.total_revenue as revenue_prev_year
    from daily_base curr 
    left join daily_base prev_week on prev_week.date = dateadd(day, -7, curr.date)
    left join daily_base prev_month on prev_month.date = dateadd(month, -1, curr.date)
    left join daily_base prev_year on prev_year.date = dateadd(year, -1, curr.date)
),

moving_averages as (
    select
        *,
        -- 7-day moving average (daily/weekend fluctuations)
        avg(total_orders) over (order by date rows between 6 preceding and current row) as rolling_avg_orders_7d,
        avg(total_revenue) over (order by date rows between 6 preceding and current row) as rolling_avg_revenue_7d,

        -- 28-day moving average (monthly trends)
        avg(total_orders) over (order by date rows between 27 preceding and current row) as rolling_avg_orders_28d,
        avg(total_revenue) over (order by date rows between 27 preceding and current row) as rolling_avg_revenue_28d,

        -- 90-day moving average (quarterly trends)
        avg(total_orders) over (order by date rows between 89 preceding and current row) as rolling_avg_orders_90d,
        avg(total_revenue) over (order by date rows between 89 preceding and current row) as rolling_avg_revenue_90d,

        -- 365-day moving average (annual trends)
        avg(total_orders) over (order by date rows between 364 preceding and current row) as rolling_avg_orders_365d,
        avg(total_revenue) over (order by date rows between 364 preceding and current row) as rolling_avg_revenue_365d
    from prior_periods
),

running_totals as (
    select
        *,
        -- Cumulative totals
        sum(total_orders) over (order by date) as cumulative_orders,
        sum(total_revenue) over (order by date) as cumulative_revenue,

        -- Year-to-date totals (resets at the start of each year)
        sum(total_orders) over (partition by year order by date) as ytd_orders,
        sum(total_revenue) over (partition by year order by date) as ytd_revenue,

        -- Quarter-to-date totals (resets at the start of each quarter)
        sum(total_orders) over (partition by year, quarter_number order by date) as qtd_orders,
        sum(total_revenue) over (partition by year, quarter_number order by date) as qtd_revenue,

        -- Month-to-date totals (resets at the start of each month)
        sum(total_orders) over (partition by year, month order by date) as mtd_orders,
        sum(total_revenue) over (partition by year, month order by date) as mtd_revenue,

        -- Week-to-date totals (resets at the start of each ISO week)
        sum(total_orders) over (partition by iso_year_week order by date) as wtd_orders,
        sum(total_revenue) over (partition by iso_year_week order by date) as wtd_revenue
    from moving_averages
),

growth_rates as (
    select
        *,
        -- Week-over-week growth rates
        round((total_orders - orders_prev_week) / nullif(orders_prev_week, 0) * 100, 2) as order_growth_wow_pct,
        round((total_revenue - revenue_prev_week) / nullif(revenue_prev_week, 0) * 100, 2) as revenue_growth_wow_pct,

        -- Month-over-month growth rates
        round((total_orders - orders_prev_month) / nullif(orders_prev_month, 0) * 100, 2) as order_growth_mom_pct,
        round((total_revenue - revenue_prev_month) / nullif(revenue_prev_month, 0) * 100, 2) as revenue_growth_mom_pct,

        -- Year-over-year growth rates
        round((total_orders - orders_prev_year) / nullif(orders_prev_year, 0) * 100, 2) as order_growth_yoy_pct,
        round((total_revenue - revenue_prev_year) / nullif(revenue_prev_year, 0) * 100, 2) as revenue_growth_yoy_pct,

        -- Efficiency Trends: Prior period AOVs
        round(revenue_prev_week / nullif(orders_prev_week, 0), 2) as aov_prev_week,
        round(revenue_prev_month / nullif(orders_prev_month, 0), 2) as aov_prev_month,
        round(revenue_prev_year / nullif(orders_prev_year, 0), 2) as aov_prev_year,

        -- Efficiency Trends: Moving Average AOVs
        round(rolling_avg_revenue_7d / nullif(rolling_avg_orders_7d, 0), 2) as rolling_avg_aov_7d,
        round(rolling_avg_revenue_28d / nullif(rolling_avg_orders_28d, 0), 2) as rolling_avg_aov_28d,
        round(rolling_avg_revenue_90d / nullif(rolling_avg_orders_90d, 0), 2) as rolling_avg_aov_90d,
        round(rolling_avg_revenue_365d / nullif(rolling_avg_orders_365d, 0), 2) as rolling_avg_aov_365d,

        -- Efficiency Trends: Running Total AOVs
        round(cumulative_revenue / nullif(cumulative_orders, 0), 2) as cumulative_aov,
        round(ytd_revenue / nullif(ytd_orders, 0), 2) as ytd_aov,
        round(qtd_revenue / nullif(qtd_orders, 0), 2) as qtd_aov,
        round(mtd_revenue / nullif(mtd_orders, 0), 2) as mtd_aov,
        round(wtd_revenue / nullif(wtd_orders, 0), 2) as wtd_aov

    from running_totals
),

final as (
    select
        -- Date dimensions
        date_key,
        date,
        year,
        quarter_number,
        month,
        iso_year_week,

        -- Metrics
        total_orders,
        delivered_orders,
        canceled_orders,
        total_revenue,
        total_freight,
        gross_revenue,
        average_order_value,
        total_reviews,
        avg_review_score,

        -- Prior periods
        orders_prev_week,
        revenue_prev_week,
        orders_prev_month,
        revenue_prev_month,
        orders_prev_year,
        revenue_prev_year,

        -- Moving averages
        rolling_avg_orders_7d,
        rolling_avg_revenue_7d,
        rolling_avg_orders_28d,
        rolling_avg_revenue_28d,
        rolling_avg_orders_90d,
        rolling_avg_revenue_90d,
        rolling_avg_orders_365d,
        rolling_avg_revenue_365d,

        -- Running totals
        cumulative_orders,
        cumulative_revenue,
        ytd_orders,
        ytd_revenue,
        qtd_orders,
        qtd_revenue,
        mtd_orders,
        mtd_revenue,
        wtd_orders,
        wtd_revenue,

        -- Growth rates
        order_growth_wow_pct,
        revenue_growth_wow_pct,
        order_growth_mom_pct,
        revenue_growth_mom_pct,
        order_growth_yoy_pct,
        revenue_growth_yoy_pct,

        -- Efficiency trends (AOV)
        --Prior period AOVs
        aov_prev_week,
        aov_prev_month,
        aov_prev_year,

        -- Moving average AOVs
        rolling_avg_aov_7d,
        rolling_avg_aov_28d,
        rolling_avg_aov_90d,
        rolling_avg_aov_365d,

        -- Running total AOVs
        cumulative_aov,
        ytd_aov,
        qtd_aov,
        mtd_aov,
        wtd_aov,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from growth_rates
)

select * from final

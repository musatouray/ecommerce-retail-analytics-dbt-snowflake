-- Pareto analysis fact table identifying products that drive the majority of revenue
-- Use this for inventory prioritization, ABC classification, and 80/20 analysis

with product_revenue as (
    select
        product_key,
        product_id,
        product_category,
        total_orders,
        total_revenue
    from {{ ref('dim_products') }}
    where total_revenue > 0 -- Exclude products with no sales to avoid skewing percentages
),

ranked_products as (
    select
        *,
        -- Pre-compute denominators for percentage calculations
        sum(total_revenue) over () as grand_total_revenue,
        count(*) over () as total_product_count,

        -- Cumulative revenue (use product_id as tie-breaker for deterministic ordering)
        sum(total_revenue) over (order by total_revenue desc, product_id asc) as cumulative_revenue,

        -- Revenue rank for display
        row_number() over (order by total_revenue desc, product_id asc) as revenue_rank
    from product_revenue
),

pareto_calculations as (
    select
        *,
        -- Cumulative percentage of revenue 
        cumulative_revenue * 100.0 / nullif(grand_total_revenue, 0) as cumulative_revenue_pct,

        -- Cumulative percentage of products
        revenue_rank * 100.0 / nullif(total_product_count, 0) as cumulative_product_pct
    from ranked_products
),

final as (
    select
        product_key,
        product_id,
        product_category,
        total_orders,
        total_revenue,
        revenue_rank,
        cumulative_revenue,
        round(cumulative_revenue_pct, 2) as cumulative_revenue_pct,
        round(cumulative_product_pct, 2) as cumulative_product_pct,
        case
            when cumulative_revenue_pct <= 80 then 'A'
            when cumulative_revenue_pct <= 95 then 'B'
            else 'C'
        end as pareto_segment,

        -- Metadata
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from pareto_calculations
)

select * from final

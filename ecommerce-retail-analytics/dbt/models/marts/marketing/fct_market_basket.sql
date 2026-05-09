with order_items as (
    select
        order_id,
        product_id,
        product_category_english as product_category
    from {{ ref('int_order_items_enriched') }}
),

-- Product popularity: Total number of orders for each product, used for calculating confidence and lift
item_popularity as (
    select
        product_id,
        product_category,
        count(distinct order_id) as total_orders_per_product 
    from order_items
    group by 1, 2
),

-- Global denominator: Total unique orders in the dataset, used for calculating support
overall_orders as (
    select
        count(distinct order_id) as overall_total_orders 
    from order_items
),

-- The Self-Join: Find pairs of products that were purchased together
product_pairs as (
    select
        a.product_id as product_a,
        b.product_id as product_b,
        a.product_category as category_a,
        b.product_category as category_b,
        count(distinct a.order_id) as pair_count
    from order_items a
    join order_items b
        on a.order_id = b.order_id
        and a.product_id < b.product_id  -- Avoid duplicate counting pairs
    group by 1, 2, 3, 4
    having count(distinct a.order_id) >= {{ var('market_basket_min_pair_count', 5) }}  -- Filter for minimum pair count
),

final as (
    select
        pp.product_a,
        pp.product_b,
        pp.category_a,
        pp.category_b,
        pp.pair_count,

        -- Product order counts for context
        ia.total_orders_per_product as product_a_order_count,
        ib.total_orders_per_product as product_b_order_count,

        -- Support: How often this pair appears in all orders
        round(pp.pair_count * 100.0 / oo.overall_total_orders, 4) as support_pct,

        -- Confidence: Probability of B given A, and A given B
        round(pp.pair_count * 100.0 / nullif(ia.total_orders_per_product, 0), 2) as confidence_a_to_b_pct,
        round(pp.pair_count * 100.0 / nullif(ib.total_orders_per_product, 0), 2) as confidence_b_to_a_pct,

        -- Lift: How much more likely the pair is vs random chance
        round((pp.pair_count * oo.overall_total_orders)::float / nullif((ia.total_orders_per_product * ib.total_orders_per_product), 0), 2) as lift
    from product_pairs pp
    join item_popularity ia on pp.product_a = ia.product_id
    join item_popularity ib on pp.product_b = ib.product_id
    cross join overall_orders oo
)

select
    {{ dbt_utils.generate_surrogate_key(['product_a', 'product_b']) }} as basket_pair_key,
    product_a,
    product_b,
    category_a,
    category_b,
    pair_count,
    product_a_order_count,
    product_b_order_count,
    support_pct,
    confidence_a_to_b_pct,
    confidence_b_to_a_pct,
    lift,

    -- Metadata
    current_timestamp as created_at,
    current_timestamp as updated_at

from final
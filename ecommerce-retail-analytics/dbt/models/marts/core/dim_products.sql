with products as (
    select *
    from {{ ref('stg_ecommerce__products') }}
),

final as (
    select
        -- Generate surrogate key for product dimension
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        p.product_id,
        p.product_category_english as product_category,
        p.name_length,
        p.description_length,
        p.photos_qty,
        p.weight_g,
        p.length_cm,
        p.height_cm,
        p.width_cm
    from products p
)

select * from final

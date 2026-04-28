with source as (

    select * from {{ source('raw', 'products') }}

),

renamed as (

    select
        trim(product_id) as product_id,
        trim(product_category_name) as product_category,
        product_name_lenght::int as name_length,
        product_description_lenght::int as description_length,
        product_photos_qty::int as photos_qty,
        product_weight_g::numeric(10,2) as weight_g,
        product_length_cm::numeric(10,2) as length_cm,
        product_height_cm::numeric(10,2) as height_cm,
        product_width_cm::numeric(10,2) as width_cm

    from source

)

select * from renamed
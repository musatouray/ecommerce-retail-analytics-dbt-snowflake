with sellers as (
    select * from {{ ref('stg_ecommerce_sellers') }}
)
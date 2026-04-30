with sellers as (
    select * from {{ ref('stg_ecommerce__sellers') }}
)

select
    seller_id,
    zip_code,
    city,
    state
from sellers
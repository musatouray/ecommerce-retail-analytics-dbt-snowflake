{% macro incremental_filter(column_name, lookback_days=3) -%}
    {%- if is_incremental() -%}
        where {{ column_name }} > (
            select dateadd(day, -{{ lookback_days }}, max({{ column_name }}))
            from {{ this }}
        )
    {%- endif -%}
{%- endmacro %}
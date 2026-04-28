{%- macro get_order_date_spine() -%}
   
   {% set date_query %}
        select
            min(order_date)::date as min_date,
            max(order_date)::date as max_date
        from {{ ref('int_orders_enriched') }}
   {% endset %}

   {% if execute %}
        {% set results = run_query(date_query) %}
        {% set start_date = results.columns[0].values()[0] %}
        {% set end_date = results.columns[1].values()[0] %}
    {% else %}
         {% set start_date = '2016-01-01' %}
         {% set end_date = '2018-12-31' %}
   {% endif %}

    {{ dbt_utils.date_spine(
          datepart="day",
          start_date="cast('" ~ start_date ~ "' as date)",
          end_date="dateadd(day, 1, cast('" ~ end_date ~ "' as date))"
     ) }}

{%- endmacro -%}
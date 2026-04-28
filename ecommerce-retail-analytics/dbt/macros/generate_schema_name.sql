{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
        Override dbt's default schema naming to use custom schema names directly.

        By default, dbt creates schemas like: <target_schema>_<custom_schema>
        Example: RAW_staging

        This macro changes it to use the custom schema name directly:
        Example: STAGING

        If no custom schema is specified, it uses the target schema.
    #}
    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema | upper }}
    {%- else -%}
        {{ custom_schema_name | upper }}
    {%- endif -%}
{%- endmacro %}

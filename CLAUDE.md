# CLAUDE.md

This file provides context for Claude Code when working on this project.

## Project Overview

E-Commerce Analytics project using dbt + Snowflake to analyze the Olist Brazilian E-Commerce dataset. The project implements RFM segmentation, cohort analysis, customer lifetime value, and other advanced SQL analytics patterns.

## Tech Stack

| Component | Tool | Version/Notes |
|-----------|------|---------------|
| Warehouse | Snowflake | Database: `ECOMMERCE_RETAIL_DB` |
| Transform | dbt | dbt-fusion 2.0.0-preview |
| Python | uv | Package manager |
| Visualization | Power BI | Connects to Snowflake marts |

## Key Commands

```bash
# Navigate to dbt directory first
cd ecommerce-retail-analytics/dbt

# Run all models and tests
dbt build

# Run only models (no tests)
dbt run

# Run only tests
dbt test

# Run specific model
dbt run --select stg_ecommerce__orders

# Run staging models only
dbt run --select staging.*

# Check connection
dbt debug

# Generate documentation
dbt docs generate
dbt docs serve
```

## Project Structure

```
ecommerce-retail-analytics-dbt-snowflake/
├── CLAUDE.md                      # This file
├── README.md                      # Project overview
├── INSTALLATION.md                # Setup guide
├── INSTRUCTIONS.md                # Execution guide
│
└── ecommerce-retail-analytics/
    ├── .env                       # Environment variables (gitignored)
    ├── pyproject.toml             # Python dependencies
    │
    ├── scripts/
    │   ├── config/                # Snowflake setup SQL scripts
    │   │   ├── 1-roles-and-user-config.sql
    │   │   ├── 2-warehouse-config.sql
    │   │   ├── 3-database-schemas-config.sql
    │   │   └── 4-grant-access-config.sql
    │   ├── download_kaggle_data.py
    │   └── load_to_snowflake.py
    │
    ├── data/                      # Downloaded CSV data (gitignored)
    │
    └── dbt/
        ├── dbt_project.yml
        ├── packages.yml           # dbt_utils, audit_helper, codegen
        │
        ├── macros/
        │   ├── generate_schema_name.sql  # Custom schema naming
        │   └── generate_date_spine.sql   # Date spine generator for dim_dates
        │
        └── models/
            ├── staging/           # Clean and type raw data
            │   ├── _sources.yml
            │   ├── _stg_ecommerce_models.yml
            │   ├── _docs.md
            │   └── stg_ecommerce__*.sql
            │
            ├── intermediate/      # Join and enrich
            │   ├── _int_models.yml
            │   ├── int_orders_enriched.sql
            │   └── int_order_items_enriched.sql
            │
            └── marts/             # Fact and dimension tables
                ├── core/          # Shared dimensions & facts
                │   ├── dim_customers.sql
                │   ├── dim_dates.sql
                │   ├── dim_products.sql
                │   ├── dim_sellers.sql
                │   └── fct_orders.sql
                ├── finance/       # Revenue & payment analytics
                │   ├── fct_daily_revenue.sql
                │   └── fct_payment_analysis.sql
                └── marketing/     # Category & geo analytics
                    ├── fct_category_performance.sql
                    └── fct_geo_performance.sql
```

## Snowflake Configuration

| Setting | Value |
|---------|-------|
| Database | `ECOMMERCE_RETAIL_DB` |
| Warehouse | `ECOMMERCE_RETAIL_WH` |
| Role | `LEAD_DATA_ENGINEER_ROLE` |

### Schema Architecture

| Schema | Purpose | Materialization |
|--------|---------|-----------------|
| `RAW` | Source data from Kaggle CSV | Tables |
| `STAGING` | Cleaned, typed, deduplicated | Views |
| `INTERMEDIATE` | Joined and enriched | Views |
| `MARTS_CORE` | Shared dimensions & facts | Tables |
| `MARTS_FINANCE` | Revenue & payment analytics | Tables |
| `MARTS_MARKETING` | Category & geo analytics | Tables |

## dbt Conventions

### Schema Naming

The project uses a custom `generate_schema_name` macro that uses schema names directly (not appending to target schema):
- Models with `+schema: staging` → `STAGING` schema (not `RAW_staging`)

### Test Syntax (dbt-fusion 2.0)

Tests require the `arguments:` wrapper:

```yaml
# Correct syntax for column-level tests
columns:
  - name: order_id
    data_tests:
      - not_null
      - relationships:
          arguments:
            to: ref('stg_ecommerce__orders')
            field: order_id
  - name: payment_type
    data_tests:
      - accepted_values:
          arguments:
            values: ["credit_card", "boleto", "voucher"]

# Model-level tests (NOT column-level) - place at model level
models:
  - name: stg_ecommerce__order_items
    data_tests:
      - dbt_utils.unique_combination_of_columns:
          arguments:
            combination_of_columns:
              - order_id
              - order_item_id
```

**Important**: `dbt_utils.unique_combination_of_columns` must be defined at the model level, not under a column. Placing it under a column causes a compilation error.

### Staging Model Pattern

All staging models follow this CTE pattern:

```sql
with source as (
    select * from {{ source('raw', 'table_name') }}
),

renamed as (
    select
        -- transformations here
    from source
)

select * from renamed
```

### Data Cleaning Conventions

- `trim()` on all string columns
- `initcap()` for city names
- `upper()` for state codes
- `lpad(..., 5, '0')` for zip codes
- `::date` or `::timestamp` for date conversions
- `::numeric(10,2)` for monetary values
- `ROW_NUMBER()` for deduplication when needed

## Source Tables (RAW Schema)

| Table | Primary Key | Notes |
|-------|-------------|-------|
| customers | customer_id | |
| orders | order_id | |
| order_items | (order_id, order_item_id) | Composite key |
| order_payments | (order_id, payment_sequential) | Composite key |
| order_reviews | review_id | Source has duplicates, dedupe in staging |
| products | product_id | |
| sellers | seller_id | |
| geolocation | zip_code | Multiple rows per zip, aggregate in staging |
| product_category_translation | product_category_name | |

## Staging Models

| Model | Key Transformations |
|-------|---------------------|
| stg_ecommerce__customers | Zip code padding, city/state formatting |
| stg_ecommerce__geolocation | GROUP BY zip_code with AVG(lat/lng) |
| stg_ecommerce__orders | Timestamp conversions, status validation |
| stg_ecommerce__order_items | Renamed shipping_deadline |
| stg_ecommerce__order_payments | Payment type validation |
| stg_ecommerce__order_reviews | ROW_NUMBER deduplication on review_id |
| stg_ecommerce__product_category_translation | Portuguese to English category translation |
| stg_ecommerce__products | Fixed typos, joins translation for English category |
| stg_ecommerce__sellers | Zip code padding, city/state formatting |

## Intermediate Models

| Model | Grain | Description |
|-------|-------|-------------|
| int_orders_enriched | order_id | Orders joined with customers, aggregated items/payments/reviews. Excludes canceled/unavailable orders. |
| int_order_items_enriched | (order_id, order_item_id) | Order items joined with orders, products, sellers. Includes English category names. |

## Mart Models

### Core (MARTS_CORE schema)

| Model | Grain | Description |
|-------|-------|-------------|
| dim_customers | customer_unique_id | Customer dimension with attributes and location |
| dim_dates | date | Date dimension generated from order date range |
| dim_products | product_id | Product dimension with English category names |
| dim_sellers | seller_id | Seller dimension with location |
| fct_orders | order_id | Order fact table with metrics |

### Finance (MARTS_FINANCE schema)

| Model | Grain | Description |
|-------|-------|-------------|
| fct_daily_revenue | date | Daily revenue aggregates |
| fct_payment_analysis | payment_type, month | Payment method performance by month |

### Marketing (MARTS_MARKETING schema)

| Model | Grain | Description |
|-------|-------|-------------|
| fct_category_performance | category, month | Category sales metrics by month |
| fct_geo_performance | state, month | Geographic performance by month |

## Custom Macros

| Macro | Purpose |
|-------|---------|
| `generate_schema_name` | Uses schema names directly without appending to target |
| `get_order_date_spine` | Generates date spine from min/max order dates using dbt_utils.date_spine |

## Testing Strategy

- **Sources**: Basic integrity (not_null, unique on PKs)
- **Staging**: Full coverage (not_null, unique, relationships, accepted_values, composite key tests)
- **Intermediate**: Key validation (not_null, unique on grain, composite key tests)
- **Marts**: Primary key validation (not_null, unique on grain)

## Known Data Issues

1. **order_reviews.review_id**: Source has duplicates - handled with ROW_NUMBER in staging
2. **geolocation**: Multiple lat/lng per zip code - handled with GROUP BY and AVG
3. **Source column typos**: `product_name_lenght` → fixed to `name_length` in staging

## dbt Packages

- `dbt-labs/dbt_utils` - Utility macros and tests
- `dbt-labs/audit_helper` - Data auditing
- `dbt-labs/codegen` - Code generation helpers

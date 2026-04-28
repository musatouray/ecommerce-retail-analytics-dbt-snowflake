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
        │   └── generate_schema_name.sql  # Custom schema naming
        │
        └── models/
            ├── staging/           # Clean and type raw data
            │   ├── _sources.yml
            │   ├── _stg_ecommerce_models.yml
            │   ├── _docs.md
            │   └── stg_ecommerce__*.sql
            │
            ├── intermediate/      # Join and enrich (TODO)
            └── marts/             # Fact and dimension tables (TODO)
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
| `MARTS` | Fact and dimension tables | Tables |

## dbt Conventions

### Schema Naming

The project uses a custom `generate_schema_name` macro that uses schema names directly (not appending to target schema):
- Models with `+schema: staging` → `STAGING` schema (not `RAW_staging`)

### Test Syntax (dbt-fusion 2.0)

Tests require the `arguments:` wrapper:

```yaml
# Correct syntax
data_tests:
  - relationships:
      arguments:
        to: ref('stg_ecommerce__orders')
        field: order_id
  - accepted_values:
      arguments:
        values: ["credit_card", "boleto", "voucher"]
  - dbt_utils.unique_combination_of_columns:
      arguments:
        combination_of_columns:
          - order_id
          - order_item_id
```

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
| stg_ecommerce__products | Fixed column name typos (lenght→length) |
| stg_ecommerce__sellers | Zip code padding, city/state formatting |

## Testing Strategy

- **Sources**: Basic integrity (not_null, unique on PKs, composite keys)
- **Staging**: Full coverage (not_null, unique, relationships, accepted_values)
- **Intermediate/Marts**: Business logic validation (TODO)

## Known Data Issues

1. **order_reviews.review_id**: Source has duplicates - handled with ROW_NUMBER in staging
2. **geolocation**: Multiple lat/lng per zip code - handled with GROUP BY and AVG
3. **Source column typos**: `product_name_lenght` → fixed to `name_length` in staging

## dbt Packages

- `dbt-labs/dbt_utils` - Utility macros and tests
- `dbt-labs/audit_helper` - Data auditing
- `dbt-labs/codegen` - Code generation helpers

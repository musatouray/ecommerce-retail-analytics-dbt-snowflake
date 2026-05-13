# GitHub Copilot Instructions

## Project Overview

dbt + Snowflake analytics project on the Olist Brazilian E-Commerce dataset. Implements RFM segmentation, cohort analysis, CLV, and churn risk using a Medallion architecture.

## Commands

All dbt commands must be run from `ecommerce-retail-analytics/dbt/`:

```bash
cd ecommerce-retail-analytics/dbt

dbt build                                        # Run all models + tests
dbt run                                          # Run models only
dbt test                                         # Run tests only
dbt run --select stg_ecommerce__orders           # Run a single model
dbt run --select staging.*                       # Run a layer
dbt build --select state:modified+ --defer \
  --state prod-manifest                          # Slim CI (modified + downstream)
dbt deps                                         # Install packages
dbt debug                                        # Verify Snowflake connection
dbt docs generate && dbt docs serve              # Generate + serve docs
```

SQL linting (warnings only, does not fail CI):

```bash
cd ecommerce-retail-analytics/dbt
sqlfluff lint models/ --dialect snowflake --config .sqlfluff
```

## Architecture

### Medallion (2 Databases)

```
ECOMMERCE_RETAIL_DB_DEV
├── RAW           ← Bronze: raw source tables (Kaggle CSVs loaded via script)
├── STAGING       ← Silver: cleaned views — always in DEV, shared across envs
├── INTERMEDIATE  ← Gold (dev)
└── MARTS         ← Gold (dev)

ECOMMERCE_RETAIL_DB_PROD
├── INTERMEDIATE  ← Gold (prod)
└── MARTS         ← Gold (prod) — Power BI connects here
```

**Critical**: The `staging` layer is hardcoded to `ECOMMERCE_RETAIL_DB_DEV` in `dbt_project.yml`. Only intermediate and marts deploy to the target database (dev or prod). This means staging models serve as the shared silver layer across all environments.

### dbt Model Layers → Snowflake Schemas

| Layer | Materialization | Schema |
|-------|----------------|--------|
| staging | view | `STAGING` (always in DEV DB) |
| intermediate | view | `INTERMEDIATE` |
| marts | table | `MARTS` |

Mart models are organized in subfolders (`core/`, `customer/`, `finance/`, `marketing/`) for code organization only — all deploy to the single `MARTS` schema.

### CI/CD

- **CI (PR → main)**: Runs Slim CI in isolated `ECOMMERCE_RETAIL_DB_DEV.CI_PR_<number>` schema. Uses `state:modified+` with deferred manifest from prod.
- **CD (merge to main)**: Deploys to `ECOMMERCE_RETAIL_DB_PROD`. Full `dbt build`. Manual `workflow_dispatch` supports `--full-refresh`.

### Schema Naming (Custom Macro)

`macros/generate_schema_name.sql` overrides dbt's default (which would produce `<target_schema>_<custom_schema>`):

- **Dev/Prod targets**: Uses `custom_schema_name` directly, uppercased (e.g., `STAGING`, `MARTS`)
- **CI target**: Prefixes with `target.schema` for isolation — except `STAGING` which is always unmodified

## Key Conventions

### dbt-fusion 2.0 Test Syntax

Tests with parameters require an `arguments:` wrapper. Without it, compilation fails:

```yaml
# ✅ Correct
- relationships:
    arguments:
      to: ref('stg_ecommerce__orders')
      field: order_id

- accepted_values:
    arguments:
      values: ["credit_card", "boleto", "voucher"]

# ✅ Composite key test — must be at MODEL level, not under a column
models:
  - name: stg_ecommerce__order_items
    data_tests:
      - dbt_utils.unique_combination_of_columns:
          arguments:
            combination_of_columns:
              - order_id
              - order_item_id

# ❌ Wrong — dbt_utils.unique_combination_of_columns under a column causes compile error
columns:
  - name: order_id
    data_tests:
      - dbt_utils.unique_combination_of_columns: ...
```

### Staging Model Pattern

Every staging model uses a two-CTE pattern:

```sql
with source as (
    select * from {{ source('raw', 'table_name') }}
),

renamed as (
    select
        trim(col) as col,
        ...
    from source
)

select * from renamed
```

### Data Cleaning Conventions

| Type | Convention |
|------|------------|
| All strings | `trim()` |
| City names | `initcap()` |
| State codes | `upper()` |
| Zip codes | `lpad(..., 5, '0')` |
| Dates | `::date` |
| Timestamps | `::timestamp` |
| Monetary | `::numeric(10,2)` |
| Deduplication | `ROW_NUMBER()` |

### SQLFluff Style

- **Keywords**: lowercase (`select`, `from`, `where`, not `SELECT`)
- **Identifiers**: lowercase
- **Indentation**: 4 spaces
- **Max line length**: 120 characters
- Linter runs in warnings-only mode (CI never fails on lint)

### Known Source Data Issues

| Issue | Solution |
|-------|----------|
| `order_reviews.review_id` has duplicates | `ROW_NUMBER()` dedup in `stg_ecommerce__order_reviews` |
| `geolocation` has multiple rows per zip | `GROUP BY zip_code` with `AVG(lat, lng)` |
| `products.product_name_lenght` typo | Fixed to `name_length` in staging |

### Project Variables

Configured in `dbt_project.yml` vars — reference with `{{ var('name') }}` in models:

- `active_days_threshold: 180`
- `customer_high_value_threshold: 500`, `customer_medium_value_threshold: 100`
- `platinum_value_threshold: 10000`, `gold_value_threshold: 1000`, `silver_value_threshold: 100`

## Packages

- `dbt-labs/dbt_utils 1.3.3` — utility macros and tests
- `dbt-labs/audit_helper 0.13.0` — data auditing
- `dbt-labs/codegen 0.13.1` — code generation helpers

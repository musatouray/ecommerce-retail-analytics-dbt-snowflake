# Olist Brazilian E-Commerce Analytics

An end-to-end data engineering project that transforms raw e-commerce data into actionable business insights using modern data stack tools.

## Overview

This project builds a complete analytics pipeline for the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. The dataset contains information about 100k orders made at multiple marketplaces in Brazil from 2016 to 2018.

## Key Analytics Questions

This pipeline enables answering business questions like:

- What is the revenue trend over time?
- Which product categories perform best?
- What is the geographic distribution of sales?
- How do different payment methods perform?
- What is the average delivery time vs. estimate?
- Which sellers have the highest performance?
- What drives customer satisfaction (review scores)?

## Architecture

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    Kaggle    │      │  Snowflake   │      │     dbt      │      │   Power BI   │
│   (Source)   │─────▶│  (Warehouse) │─────▶│ (Transform)  │─────▶│   (Visualize)│
└──────────────┘      └──────────────┘      └──────────────┘      └──────────────┘
     CSV via              RAW Schema           Staging,            Dashboards &
    Kaggle API                               Intermediate,          Reports
                                               & Marts
```

### Data Flow

1. **Extract**: Download CSV files from Kaggle using the Kaggle API
2. **Load**: Ingest raw CSV data into Snowflake's RAW schema
3. **Transform**: Use dbt to build layered transformations:
   - **Staging**: Clean and standardize raw data
   - **Intermediate**: Join and enrich data with business logic
   - **Marts**: Create dimensional models for analytics
4. **Visualize**: Connect Power BI to Snowflake marts for reporting

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Source | Kaggle API | Download e-commerce dataset |
| Warehouse | Snowflake | Cloud data storage and compute |
| Transform | dbt | SQL-based data transformation |
| Orchestration | dbt CLI | Run and test transformations |
| Package Manager | uv | Python dependency management |
| Visualization | Power BI | Business intelligence dashboards |

## Dataset Description

The Olist dataset includes:

| Table | Description | Records |
|-------|-------------|---------|
| orders | Order header information | ~100k |
| order_items | Line items for each order | ~113k |
| order_payments | Payment details per order | ~104k |
| order_reviews | Customer reviews and ratings | ~100k |
| customers | Customer information | ~100k |
| products | Product catalog | ~33k |
| sellers | Seller information | ~3k |
| geolocation | Brazilian zip code coordinates | ~1M |
| product_category_translation | Portuguese to English mapping | 71 |

## Data Model

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         MARTS LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │    Core     │  │   Finance   │  │  Marketing  │              │
│  │ fct_orders  │  │ fct_daily_  │  │ fct_category│              │
│  │ dim_*       │  │ revenue     │  │ _performance│              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                    INTERMEDIATE LAYER                           │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │ int_orders_enriched │  │ int_order_items_    │               │
│  │                     │  │ enriched            │               │
│  └─────────────────────┘  └─────────────────────┘               │
├─────────────────────────────────────────────────────────────────┤
│                      STAGING LAYER                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │stg_olist_│ │stg_olist_│ │stg_olist_│ │stg_olist_│  ...      │
│  │_orders   │ │_customers│ │_products │ │_sellers  │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                       RAW LAYER                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Snowflake RAW Schema (CSV data loaded via Python)       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Dimensional Model

**Fact Tables:**
- `fct_orders` - Grain: one row per order with metrics
- `fct_daily_revenue` - Grain: one row per day
- `fct_category_performance` - Grain: one row per category per month
- `fct_geo_performance` - Grain: one row per city per month
- `fct_payment_analysis` - Grain: one row per payment type per month

**Dimension Tables:**
- `dim_customers` - Customer attributes and lifetime metrics
- `dim_products` - Product catalog with categories
- `dim_sellers` - Seller information and performance tiers

## Project Structure

```
ecommerce-retail-analytics-dbt-snowflake/
├── README.md                   # Project overview (this file)
├── INSTALLATION.md             # Setup and installation guide
├── INSTRUCTIONS.md             # Detailed execution guide
│
└── olist-retail-analytics/
    ├── .env.example            # Environment variables template
    ├── .gitignore
    ├── pyproject.toml          # Python dependencies (uv)
    ├── uv.lock                 # Locked dependency versions
    │
    ├── scripts/                # Data extraction and loading
    │
    ├── data/                   # Downloaded data (gitignored)
    │
    └── dbt/
        ├── dbt_project.yml
        ├── models/
        │   ├── staging/        # Staging models + sources.yml
        │   ├── intermediate/   # Enriched models
        │   └── marts/          # Fact and dimension tables
        ├── macros/
        ├── tests/
        └── seeds/
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/musatouray/ecommerce-retail-analytics-dbt-snowflake.git
cd ecommerce-retail-analytics-dbt-snowflake/olist-retail-analytics

# Install dependencies (requires uv and Python 3.12)
uv venv --python 3.12
uv sync

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Test connection
cd dbt
dbt debug
```

For detailed setup instructions including Snowflake key-pair authentication, see **[INSTALLATION.md](INSTALLATION.md)**.

## License

This project uses the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) released under CC BY-NC-SA 4.0.

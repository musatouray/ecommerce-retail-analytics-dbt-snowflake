# Olist Brazilian E-Commerce Analytics

An end-to-end data engineering project that transforms raw e-commerce data into actionable business insights using modern data stack tools.

## Overview

This project builds a complete analytics pipeline for the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. The dataset contains information about 100k orders made at multiple marketplaces in Brazil from 2016 to 2018.

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

## Setup

### Prerequisites

- Python 3.12 (dbt doesn't support Python 3.13+ yet)
- [uv](https://docs.astral.sh/uv/) - Fast Python package manager
- Snowflake account with key-pair authentication
- Kaggle account (for data download)

### 1. Clone the Repository

```bash
git clone https://github.com/musatouray/ecommerce-retail-analytics-dbt-snowflake.git
cd ecommerce-retail-analytics-dbt-snowflake/olist-retail-analytics
```

### 2. Install Python 3.12 and Dependencies

```bash
# Install Python 3.12 via uv
uv python install 3.12

# Create virtual environment with Python 3.12
uv venv --python 3.12

# Install dependencies
uv sync
```

### 3. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your credentials
```

### 4. Set Up Snowflake Key-Pair Authentication

Generate an RSA key pair:

```bash
# Create directory for keys
mkdir ~/.snowflake
cd ~/.snowflake

# Generate private key (without passphrase)
openssl genrsa -out rsa_key_temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -in rsa_key_temp.pem -out rsa_key.p8 -nocrypt
rm rsa_key_temp.pem

# Or with passphrase (more secure)
openssl genrsa -out rsa_key_temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -in rsa_key_temp.pem -out rsa_key.p8 -v2 aes256
rm rsa_key_temp.pem

# Generate public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

Assign the public key to your Snowflake user:

```sql
-- In Snowflake, run:
ALTER USER YOUR_USERNAME SET RSA_PUBLIC_KEY='your_public_key_content_here';
```

### 5. Configure dbt Profile

Create `~/.dbt/profiles.yml`:

```yaml
olist_retail_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      threads: 16
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      private_key_path: ~/.snowflake/rsa_key.p8
      private_key_passphrase: "{{ env_var('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE') }}"  # if using passphrase
```

### 6. Verify Connection

```bash
# Activate virtual environment
# Windows PowerShell:
.venv\Scripts\Activate.ps1
# Linux/Mac:
source .venv/bin/activate

# Load environment variables and test
cd dbt
dbt debug
```

## Key Analytics Questions

This pipeline enables answering questions like:

- What is the revenue trend over time?
- Which product categories perform best?
- What is the geographic distribution of sales?
- How do different payment methods perform?
- What is the average delivery time vs. estimate?
- Which sellers have the highest performance?
- What drives customer satisfaction (review scores)?

## License

This project uses the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) released under CC BY-NC-SA 4.0.

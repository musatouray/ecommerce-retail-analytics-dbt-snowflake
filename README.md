# E-Commerce Analytics

An advanced SQL analytics project demonstrating production-grade data modeling patterns including RFM segmentation, cohort analysis, customer lifetime value, and funnel optimization — built with dbt, Snowflake, and Power BI.

## Overview

This project builds a complete analytics pipeline for the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle, containing 100k orders from Brazilian marketplaces (2016-2018).

Beyond basic reporting, this project showcases **advanced SQL patterns** used by data teams at top companies to drive real business decisions — customer segmentation, revenue attribution, churn prediction, and operational optimization.

## Key Analytics Questions

### Customer Segmentation (RFM Analysis)
- How can we segment customers into actionable groups (Champions, At-Risk, Lost) based on purchase behavior?
- Which customer segments should marketing prioritize for retention vs. re-activation campaigns?
- What is the revenue contribution of each RFM segment?

### Customer Lifetime Value (CLV)
- What is the predicted lifetime value of customers acquired this quarter?
- How does CLV vary across customer segments and acquisition channels?
- Which customer cohorts have the highest ROI potential?

### Pareto Analysis (80/20 Rule)
- Which 20% of products generate 80% of revenue?
- Which customers drive the majority of sales volume?
- What percentage of sellers account for most marketplace GMV?

### Funnel & Conversion Analysis
- What is the conversion rate from order placement to delivery confirmation?
- Where are the biggest drop-offs in the customer journey?
- How does review submission rate correlate with delivery performance?

### Cohort Analysis
- How does purchasing behavior differ between monthly acquisition cohorts?
- What is the retention curve for customers acquired in each quarter?
- Do newer cohorts show improving or declining engagement trends?

### Churn Prediction Indicators
- Which customers haven't purchased in 90+ days but were previously active?
- What behavioral signals indicate a customer is at risk of churning?
- What is our customer reactivation rate after dormancy?

### Market Basket Analysis
- Which products are frequently purchased together?
- What cross-sell opportunities exist based on co-purchase patterns?
- How can we optimize product bundling recommendations?

### Time Intelligence & Trends
- What is the month-over-month and year-over-year revenue growth?
- How do 7-day and 30-day moving averages reveal sales trends?
- What seasonal patterns exist in purchasing behavior?

### Seller Performance Scoring
- How can we rank sellers using a composite score (delivery time, reviews, volume)?
- Which sellers consistently underperform on delivery estimates?
- What is the correlation between seller ratings and repeat purchases?

### Geographic Performance
- Which regions have the highest average order value?
- How does delivery performance vary by customer location?
- Where are the untapped market opportunities?

## Advanced SQL Patterns

| Pattern | Business Value | Key SQL Features |
|---------|----------------|------------------|
| RFM Analysis | Customer segmentation | `NTILE()`, `CASE WHEN` scoring |
| Pareto Analysis | Focus on high-impact items | `SUM() OVER`, cumulative percentages |
| Customer Lifetime Value | Revenue forecasting | Cohort averages, predictive aggregations |
| Funnel Analysis | Conversion optimization | `COUNT(CASE WHEN...)`, stage ratios |
| Cohort Analysis | Retention tracking | `DATE_TRUNC`, cohort pivots |
| Market Basket | Cross-sell opportunities | Self-joins, co-occurrence matrices |
| Churn Indicators | Proactive retention | `DATEDIFF`, `LAG()`, behavioral flags |
| Time Intelligence | Trend analysis | `LAG()`, moving averages, YoY/MoM |
| Seller Scoring | Vendor management | `PERCENT_RANK()`, weighted composites |
| Geo Performance | Regional strategy | Location-based aggregations |

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
│  │stg_ecomm_│ │stg_ecomm_│ │stg_ecomm_│ │stg_ecomm_│  ...      │
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
- `dim_customers` - Customer attributes and location
- `dim_dates` - Date dimension with calendar attributes
- `dim_products` - Product catalog with English categories
- `dim_sellers` - Seller information and location

## Project Structure

```
ecommerce-retail-analytics-dbt-snowflake/
├── README.md                   # Project overview (this file)
├── INSTALLATION.md             # Setup and installation guide
├── INSTRUCTIONS.md             # Detailed execution guide
│
└── ecommerce-retail-analytics/
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
        │   └── marts/
        │       ├── core/       # Shared dimensions & facts
        │       ├── finance/    # Revenue & payment analytics
        │       └── marketing/  # Category & geo analytics
        ├── macros/
        ├── tests/
        └── seeds/
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/musatouray/ecommerce-retail-analytics-dbt-snowflake.git
For detailed setup instructions including Snowflake key-pair authentication, see **[INSTALLATION.md](INSTALLATION.md)**.

## License

This project uses the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) released under CC BY-NC-SA 4.0.

# Functionalities to add to this porfolio project

✅ Generate synthetic data for incremental ETL Pipeline (Using Docker, Faker, Airflow, S3 & COPY INTO RAW)
    ┌─────────────────────┬──────────────────────────────────────┬───────────────────────────────────────────┐
    │ Component           │ Choice                               │ Why                                       │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Storage             │ AWS S3                               │ Native Snowpipe, LocalStack for local dev │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Ingestion           │ Snowflake External Stage + COPY INTO │ Synchronous, Airflow-orchestrable         │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Orchestration       │ Airflow on Docker Compose            │ Industry standard, shows DAG design       │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Data generation     │ Faker + Pandas                       │ Simple, controllable                      │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Airflow → Snowflake │ SnowflakeOperator or astro-sdk       │ Official provider                         │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Airflow → S3        │ S3Hook                               │ Mature, well-documented                   │
    ├─────────────────────┼──────────────────────────────────────┼───────────────────────────────────────────┤
    │ Local S3 mock       │ LocalStack                           │ Test without AWS costs                    │
    └─────────────────────┴──────────────────────────────────────┴───────────────────────────────────────────┘
    ▪ generate_data : Faker generates daily CSV
    ▪ upload_to_S3 : Lands in s3://bucket/YYYY/MM/
    ▪ copy_into_raw : COPY INTO Snowfalke RAW
    ▪ backfill : current data is between 2016 to 2018, backfill up to current_date then generate daily files to test all edge cases like:
✅ Data Quality & Observability (Data Contracts)
✅ Idempotency 
✅ Late-arriving data handling
✅ Backfill
✅ Implement Change Data Capture (CDC)
✅ Schema Evolution or Schema Drift
✅ Partitioning, clustering keys
✅ Query optimization
✅ Data Lineage Visualization (Using dbt)
✅ Power BI Dashboard
✅ BG/NBD Predictive Model via dbt Python for predictive_ltv
✅ Self-Correcting Agentic SQL Analyst - An Agentic RAG using crewAI / LangGraph / Microsoft Agent Framework SDK
✅ Streamlit App
✅ Cost Monitoring (Snowflake query costs, credit usage alerts)
✅ Unit Tests (dbt unit testing for complex SQL logic)

## Agentic Analytics Engineering

✅ Agentic Analytics Engineering
    ✅CONTEXT FILES
        ▪ CLAUDE.md : Entry point for claude code. Points to AGENTS.md
        ▪ AGENTS.md : The brain - describes role, context, tech stack, directory structure, and a menu of skills
    ✅ SUB-AGENTS
        ▪ code-reviewer : On-demand reviews SQL only. Does not write code. Called by skills on-demand
        ▪ doc-reviewer : Reviews YAML descriptions, checks format, sentence quality, etc. on-demand
    ✅ SKILLS - STEP-BY-STEP PROCEDURES
        ▪ /develop : scaffolds SQL, builds logic and creates YAML following conventions
        ▪ /test : Runs dbt tests, spot-checks via warehouse queries, impacts analysis across lineage
        ▪ /deploy : Commits changes to repo, opens a draft PR with ticket context
        ▪ /check-test-failures : Queries production test results and suggests fixes
    ✅ REFERENCES - LAZY-LOADED CONVENTIONS
        ▪ dbt-conventions.md : General conventions about dbt development
        ▪ sql-conventions.md : Loaded only when writing SQL
        ▪ yaml-conventions.md : How to produce correct YAML files
        ▪ data-warehouse.md : How to query the data warehouse - databases, schemas, etc.

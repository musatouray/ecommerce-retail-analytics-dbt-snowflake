-- =================================================
-- E-COMMERCE RETAIL ANALYTICS
-- 3. Database and Schemas Setup
-- =================================================
-- Run as: SYSADMIN
-- Purpose: Create database and schema structure for layered dbt architecture
-- =================================================

USE ROLE SYSADMIN;

-- =================================================
-- DATABASE
-- =================================================

CREATE DATABASE IF NOT EXISTS ECOMMERCE_RETAIL_DB
    COMMENT = 'E-Commerce retail analytics data warehouse';

-- =================================================
-- SCHEMAS
-- =================================================

-- RAW: Landing zone for source data
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_RETAIL_DB.RAW
    COMMENT = 'Landing zone: raw CSV/JSON data from external sources (Kaggle)';

-- STAGING: Cleaned and typed source data
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_RETAIL_DB.STAGING
    COMMENT = 'dbt staging layer: cleaned, typed, and deduplicated source data';

-- INTERMEDIATE: Business logic transformations
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_RETAIL_DB.INTERMEDIATE
    COMMENT = 'dbt intermediate layer: joined and enriched business entities';

-- MARTS: Business-ready analytics tables
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_RETAIL_DB.MARTS
    COMMENT = 'dbt marts layer: fact and dimension tables for BI consumption';

-- SEEDS: Reference/lookup data
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_RETAIL_DB.SEEDS
    COMMENT = 'dbt seeds: static reference data loaded from CSV files';

-- =================================================
-- SCHEMA ARCHITECTURE
-- =================================================
--
--  External Sources (Kaggle CSV)
--           │
--           ▼
--    ┌──────────────┐
--    │     RAW      │  Landing zone (tables)
--    └──────┬───────┘
--           │
--           ▼
--    ┌──────────────┐
--    │   STAGING    │  Clean + type cast (views)
--    └──────┬───────┘
--           │
--           ▼
--    ┌──────────────┐
--    │ INTERMEDIATE │  Join + enrich (tables)
--    └──────┬───────┘
--           │
--           ▼
--    ┌──────────────┐
--    │    MARTS     │  Fact + Dimension (tables)
--    └──────────────┘
--           │
--           ▼
--      Power BI / Analytics

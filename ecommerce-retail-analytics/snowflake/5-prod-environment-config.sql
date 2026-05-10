-- ============================================================================
-- MEDALLION ARCHITECTURE WITH ENVIRONMENT SEPARATION
-- ============================================================================
--
-- Architecture:
--   ECOMMERCE_RETAIL_DB_DEV  → Bronze + Silver + Gold (Dev)
--   ECOMMERCE_RETAIL_DB_PROD → Gold only (reads from DEV.Silver)
--
-- Medallion Layers:
--   Bronze (RAW)        → Immutable source data
--   Silver (STAGING)    → Cleaned, validated, typed
--   Gold (INT + MARTS)  → Business aggregates, analytics-ready
--
-- Key Design Decisions:
--   1. Bronze + Silver in DEV only (no duplication, cost efficient)
--   2. Gold layer separated by environment (Dev vs Prod)
--   3. PROD reads from DEV.STAGING via cross-database reference
--   4. Only business logic (Gold) needs environment isolation
--
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 1: CREATE DEV DATABASE (Bronze + Silver + Gold)
-- ============================================================================
-- This is the landing zone for raw data AND development environment

CREATE DATABASE IF NOT EXISTS ECOMMERCE_RETAIL_DB_DEV
    COMMENT = 'Development: Bronze (RAW) + Silver (STAGING) + Gold (INT/MARTS)';

USE DATABASE ECOMMERCE_RETAIL_DB_DEV;

-- Bronze Layer (Raw, immutable source data)
CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Bronze Layer - Raw source data from Kaggle CSV';

-- Silver Layer (Cleaned, validated)
CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Silver Layer - Cleaned and typed data';

-- Gold Layer (Business aggregates - Dev)
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE
    COMMENT = 'Gold Layer - Joined and enriched models (Dev)';

CREATE SCHEMA IF NOT EXISTS MARTS
    COMMENT = 'Gold Layer - Fact and dimension tables (Dev)';

-- ============================================================================
-- STEP 2: CREATE PROD DATABASE (Gold Only)
-- ============================================================================
-- Production only contains business-critical analytics tables
-- Reads from DEV.STAGING (Silver layer) via cross-database reference

CREATE DATABASE IF NOT EXISTS ECOMMERCE_RETAIL_DB_PROD
    COMMENT = 'Production: Gold layer only (INT/MARTS) - Dashboards connect here';

USE DATABASE ECOMMERCE_RETAIL_DB_PROD;

-- Gold Layer (Business aggregates - Prod)
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE
    COMMENT = 'Gold Layer - Joined and enriched models (Prod)';

CREATE SCHEMA IF NOT EXISTS MARTS
    COMMENT = 'Gold Layer - Fact and dimension tables (Prod) - BI tools connect here';

-- ============================================================================
-- STEP 3: MIGRATE RAW DATA FROM EXISTING DATABASE
-- ============================================================================
-- Copy raw tables from current database to DEV.RAW

-- Check if source database exists and copy data
CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.CUSTOMERS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.CUSTOMERS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.ORDERS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.ORDERS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.ORDER_ITEMS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.ORDER_ITEMS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.ORDER_PAYMENTS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.ORDER_PAYMENTS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.ORDER_REVIEWS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.ORDER_REVIEWS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.PRODUCTS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.PRODUCTS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.SELLERS AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.SELLERS;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.GEOLOCATION AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.GEOLOCATION;

CREATE OR REPLACE TABLE ECOMMERCE_RETAIL_DB_DEV.RAW.PRODUCT_CATEGORY_NAME_TRANSLATION AS
SELECT * FROM ECOMMERCE_RETAIL_DB.RAW.PRODUCT_CATEGORY_NAME_TRANSLATION;

-- ============================================================================
-- STEP 4: GRANT PERMISSIONS
-- ============================================================================

-- ----- DEV DATABASE (Full Access) -----
GRANT USAGE ON DATABASE ECOMMERCE_RETAIL_DB_DEV TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT CREATE SCHEMA ON DATABASE ECOMMERCE_RETAIL_DB_DEV TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_DEV.RAW TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_DEV.STAGING TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_DEV.INTERMEDIATE TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_DEV.MARTS TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT ALL ON ALL TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_DEV.RAW TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_DEV.RAW TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE VIEWS IN SCHEMA ECOMMERCE_RETAIL_DB_DEV.STAGING TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_DEV.INTERMEDIATE TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_DEV.MARTS TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- ----- PROD DATABASE (Full Access for CD Pipeline) -----
GRANT USAGE ON DATABASE ECOMMERCE_RETAIL_DB_PROD TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_PROD.INTERMEDIATE TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON SCHEMA ECOMMERCE_RETAIL_DB_PROD.MARTS TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_PROD.INTERMEDIATE TO ROLE LEAD_DATA_ENGINEER_ROLE;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB_PROD.MARTS TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- ============================================================================
-- STEP 5: VERIFY SETUP
-- ============================================================================

-- Show databases
SHOW DATABASES LIKE 'ECOMMERCE_RETAIL_DB%';

-- Verify medallion architecture
SELECT
    'DEV' as database_name,
    'Bronze' as medallion_layer,
    'RAW' as schema_name,
    COUNT(*) as table_count
FROM ECOMMERCE_RETAIL_DB_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW'

UNION ALL

SELECT 'DEV', 'Silver', 'STAGING', COUNT(*)
FROM ECOMMERCE_RETAIL_DB_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'STAGING'

UNION ALL

SELECT 'DEV', 'Gold', 'INTERMEDIATE', COUNT(*)
FROM ECOMMERCE_RETAIL_DB_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'INTERMEDIATE'

UNION ALL

SELECT 'DEV', 'Gold', 'MARTS', COUNT(*)
FROM ECOMMERCE_RETAIL_DB_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'MARTS'

UNION ALL

SELECT 'PROD', 'Gold', 'INTERMEDIATE', COUNT(*)
FROM ECOMMERCE_RETAIL_DB_PROD.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'INTERMEDIATE'

UNION ALL

SELECT 'PROD', 'Gold', 'MARTS', COUNT(*)
FROM ECOMMERCE_RETAIL_DB_PROD.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'MARTS'

ORDER BY 1, 2, 3;

-- Verify RAW data was copied
SELECT 'CUSTOMERS' as table_name, COUNT(*) as rows FROM ECOMMERCE_RETAIL_DB_DEV.RAW.CUSTOMERS
UNION ALL SELECT 'ORDERS', COUNT(*) FROM ECOMMERCE_RETAIL_DB_DEV.RAW.ORDERS
UNION ALL SELECT 'ORDER_ITEMS', COUNT(*) FROM ECOMMERCE_RETAIL_DB_DEV.RAW.ORDER_ITEMS
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM ECOMMERCE_RETAIL_DB_DEV.RAW.PRODUCTS;

-- ============================================================================
-- ARCHITECTURE DIAGRAM
-- ============================================================================
--
--  ┌─────────────────────────────────────────────────────────────────────────┐
--  │                    MEDALLION + ENVIRONMENT ARCHITECTURE                 │
--  ├─────────────────────────────────────────────────────────────────────────┤
--  │                                                                          │
--  │   ECOMMERCE_RETAIL_DB_DEV                                               │
--  │   ┌─────────────────────────────────────────────────────────────────┐   │
--  │   │ BRONZE (RAW)          │ Source data lands here                  │   │
--  │   ├───────────────────────┼─────────────────────────────────────────┤   │
--  │   │ SILVER (STAGING)      │ Cleaned views ──────────────────────┐   │   │
--  │   ├───────────────────────┼─────────────────────────────────────│───┤   │
--  │   │ GOLD (INT + MARTS)    │ Dev analytics                       │   │   │
--  │   └───────────────────────┴─────────────────────────────────────│───┘   │
--  │                                                                  │       │
--  │   ECOMMERCE_RETAIL_DB_PROD                                       │       │
--  │   ┌───────────────────────┬─────────────────────────────────────│───┐   │
--  │   │ GOLD (INT + MARTS)    │ Prod analytics  ◄────────────────────┘   │   │
--  │   │                       │ (reads from DEV.STAGING)                 │   │
--  │   └───────────────────────┴──────────────────────────────────────────┘   │
--  │                                                                          │
--  │   ✅ Medallion: Bronze → Silver → Gold                                  │
--  │   ✅ Cost Efficient: No Bronze/Silver duplication                       │
--  │   ✅ Environment Isolation: Dev and Prod separated                      │
--  │                                                                          │
--  └─────────────────────────────────────────────────────────────────────────┘
--
-- ============================================================================
-- GITHUB SECRETS
-- ============================================================================
--
--   SNOWFLAKE_DATABASE      = ECOMMERCE_RETAIL_DB_DEV   (for CI)
--   SNOWFLAKE_DATABASE_PROD = ECOMMERCE_RETAIL_DB_PROD  (for CD)
--
-- ============================================================================
-- OPTIONAL: CLEANUP OLD DATABASE
-- ============================================================================
-- Once verified, you can drop the old database:
-- DROP DATABASE ECOMMERCE_RETAIL_DB;
--
-- ============================================================================

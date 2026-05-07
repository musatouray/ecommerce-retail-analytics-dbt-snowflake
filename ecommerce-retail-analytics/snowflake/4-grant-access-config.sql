-- =================================================
-- E-COMMERCE RETAIL ANALYTICS
-- 4. Grant Access Configuration
-- =================================================
-- Run as: ACCOUNTADMIN (or SECURITYADMIN for grants)
-- Purpose: All permission grants in one place
-- Dependencies: Run after files 1, 2, and 3
-- =================================================

USE ROLE ACCOUNTADMIN;

-- =================================================
-- WAREHOUSE GRANTS
-- =================================================

GRANT USAGE, OPERATE ON WAREHOUSE ECOMMERCE_RETAIL_WH
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT USAGE ON WAREHOUSE ECOMMERCE_RETAIL_WH
    TO ROLE BI_READONLY_ROLE;

-- =================================================
-- DATABASE GRANTS
-- =================================================

GRANT USAGE ON DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT USAGE ON DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE BI_READONLY_ROLE;

-- =================================================
-- SCHEMA GRANTS - LEAD_DATA_ENGINEER_ROLE
-- =================================================

-- RAW: Full access for data loading
GRANT USAGE, CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT, CREATE PIPE
    ON SCHEMA ECOMMERCE_RETAIL_DB.RAW
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- STAGING: Create views (ephemeral/views in dbt)
GRANT USAGE, CREATE TABLE, CREATE VIEW
    ON SCHEMA ECOMMERCE_RETAIL_DB.STAGING
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- INTERMEDIATE: Create tables
GRANT USAGE, CREATE TABLE, CREATE VIEW
    ON SCHEMA ECOMMERCE_RETAIL_DB.INTERMEDIATE
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- MARTS: Create fact/dimension tables
GRANT USAGE, CREATE TABLE, CREATE VIEW
    ON SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- SEEDS: Create tables for reference data
GRANT USAGE, CREATE TABLE, CREATE VIEW
    ON SCHEMA ECOMMERCE_RETAIL_DB.SEEDS
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- =================================================
-- SCHEMA GRANTS - BI_READONLY_ROLE
-- =================================================

-- BI role only needs access to MARTS (and optionally SEEDS for lookups)
GRANT USAGE ON SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE BI_READONLY_ROLE;

GRANT USAGE ON SCHEMA ECOMMERCE_RETAIL_DB.SEEDS
    TO ROLE BI_READONLY_ROLE;

-- =================================================
-- TABLE/VIEW GRANTS - LEAD_DATA_ENGINEER_ROLE
-- =================================================

-- Current objects
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
    ON ALL TABLES IN DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT SELECT
    ON ALL VIEWS IN DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- Future objects (auto-grant on new tables/views)
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
    ON FUTURE TABLES IN DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

GRANT SELECT
    ON FUTURE VIEWS IN DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- =================================================
-- TABLE/VIEW GRANTS - BI_READONLY_ROLE
-- =================================================

-- Current objects in MARTS
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE BI_READONLY_ROLE;

GRANT SELECT ON ALL VIEWS IN SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE BI_READONLY_ROLE;

-- Current objects in SEEDS
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE_RETAIL_DB.SEEDS
    TO ROLE BI_READONLY_ROLE;

-- Future objects in MARTS (auto-grant on new tables/views)
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE BI_READONLY_ROLE;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA ECOMMERCE_RETAIL_DB.MARTS
    TO ROLE BI_READONLY_ROLE;

-- Future objects in SEEDS
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE_RETAIL_DB.SEEDS
    TO ROLE BI_READONLY_ROLE;

-- =================================================
-- FUTURE SCHEMA GRANTS (if new schemas are added)
-- =================================================

GRANT USAGE ON FUTURE SCHEMAS IN DATABASE ECOMMERCE_RETAIL_DB
    TO ROLE LEAD_DATA_ENGINEER_ROLE;

-- =================================================
-- VERIFICATION QUERIES
-- =================================================
-- Run these to verify grants are applied correctly:

SHOW GRANTS TO ROLE LEAD_DATA_ENGINEER_ROLE;
SHOW GRANTS TO ROLE BI_READONLY_ROLE;
SHOW GRANTS ON DATABASE ECOMMERCE_RETAIL_DB;
SHOW GRANTS ON WAREHOUSE ECOMMERCE_RETAIL_WH;

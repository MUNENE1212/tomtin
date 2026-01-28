-- Indexing Strategy - Multi-Business ERP System
-- PostgreSQL 15+
-- Purpose: Optimize query performance for <500ms API response time

-- =============================================================================
-- INDEXING PRINCIPLES
-- =============================================================================

/*
1. INDEX ALL FOREIGN KEYS
   - Every foreign key gets an index
   - Improves JOIN performance
   - Speeds up CASCADE operations

2. COMPOSITE INDEXES FOR COMMON QUERY PATTERNS
   - (business_id, date) for time-series queries
   - (account_id, date) for ledger queries
   - (status, date) for workflow queries

3. PARTIAL INDEXES FOR FILTERED DATA
   - Active records only (is_active = TRUE)
   - Pending transactions only
   - Reduces index size and improves performance

4. COVERING INDEXES (INCLUDE)
   - Include frequently accessed columns
   - Reduces table lookups
   - Improves query performance

5. BRIN INDEXES FOR TIME-SERIES DATA
   - For large tables with time-based queries
   - Smaller index size
   - Good for ledger, audit_log
*/

-- =============================================================================
-- CRITICAL INDEXES (Financial Core)
-- =============================================================================

-- Journal Entry: Business + Date (dashboard queries)
CREATE INDEX idx_je_business_date
ON journal_entry(business_id, transaction_date DESC)
INCLUDE (entry_number, total_debit, total_credit, status);

-- Journal Entry: Entry number lookup
CREATE INDEX idx_je_entry_number
ON journal_entry(entry_number);

-- Journal Entry Line: Journal entry lookup
CREATE INDEX idx_jel_journal_entry
ON journal_entry_line(journal_entry_id)
INCLUDE (account_id, is_debit, amount);

-- Journal Entry Line: Account lookup
CREATE INDEX idx_jel_account
ON journal_entry_line(account_id);

-- =============================================================================
-- LEDGER INDEXES (Most Critical for Performance)
-- =============================================================================

-- Ledger: Account + Date (account statement queries)
CREATE INDEX idx_ledger_account_date
ON ledger(account_id, transaction_date DESC)
INCLUDE (is_debit, amount, balance_after, description);

-- Ledger: Business + Date (business financial reports)
CREATE INDEX idx_ledger_business_date
ON ledger(business_id, transaction_date DESC)
INCLUDE (transaction_type_id, is_debit, amount);

-- Ledger: Reference number (M-Pesa reconciliation)
CREATE INDEX idx_ledger_reference
ON ledger(reference_number)
WHERE reference_number IS NOT NULL;

-- Ledger: Date DESC for recent transactions
CREATE INDEX idx_ledger_date_desc
ON ledger(transaction_date DESC, account_id)
INCLUDE (business_id, is_debit, amount, description);

-- BRIN index for large-scale time-series (optional, when > 1M rows)
CREATE INDEX idx_ledger_date_brin
ON ledger USING BRIN(transaction_date);

-- =============================================================================
-- BUSINESS INDEXES
-- =============================================================================

-- Business: Code lookup
CREATE INDEX idx_business_code
ON business(code)
WHERE is_active = TRUE;

-- Business: Type lookup
CREATE INDEX idx_business_type
ON business(business_type)
WHERE is_active = TRUE;

-- =============================================================================
-- WATER BUSINESS INDEXES
-- =============================================================================

-- Water Inventory: Business + Product Size
CREATE INDEX idx_water_inv_business_size
ON water_inventory(business_id, product_size_id)
INCLUDE (quantity, selling_price);

-- Water Sale: Business + Date (daily sales reports)
CREATE INDEX idx_water_sale_business_date
ON water_sale(business_id, sale_date DESC)
INCLUDE (total_amount, payment_method);

-- Water Sale: Customer lookup
CREATE INDEX idx_water_sale_customer
ON water_sale(customer_id)
WHERE customer_id IS NOT NULL;

-- Water Production: Business + Date
CREATE INDEX idx_water_prod_business_date
ON water_production(business_id, production_date DESC)
INCLUDE (quantity_produced, production_cost);

-- =============================================================================
-- LAUNDRY BUSINESS INDEXES
-- =============================================================================

-- Laundry Job: Business + Status + Date (pending jobs query)
CREATE INDEX idx_laundry_job_status_date
ON laundry_job(business_id, status, received_date DESC)
INCLUDE (job_number, customer_id, total_amount, balance_due)
WHERE status IN ('received', 'washing', 'ready');

-- Laundry Job: Customer lookup
CREATE INDEX idx_laundry_job_customer
ON laundry_job(customer_id, received_date DESC);

-- Laundry Job: Job number lookup
CREATE INDEX idx_laundry_job_number
ON laundry_job(job_number);

-- Laundry Job: Aging query (jobs > 30 days)
CREATE INDEX idx_laundry_job_aging
ON laundry_job(received_date)
WHERE status IN ('received', 'washing', 'ready') AND received_date < CURRENT_DATE - INTERVAL '30 days';

-- =============================================================================
-- RETAIL BUSINESS INDEXES
-- =============================================================================

-- Retail Inventory: Business + Product
CREATE INDEX idx_retail_inv_business_product
ON retail_inventory(business_id, product_id)
INCLUDE (quantity_in_stock, selling_price, reorder_level);

-- Retail Inventory: Low stock alert
CREATE INDEX idx_retail_inv_low_stock
ON retail_inventory(business_id, quantity_in_stock)
WHERE quantity_in_stock <= reorder_level;

-- Retail Product: Full-text search
CREATE INDEX idx_retail_product_name_gin
ON retail_product USING gin(to_tsvector('english', name))
WHERE is_active = TRUE;

-- Retail Product: Barcode/product code
CREATE INDEX idx_retail_product_code
ON retail_product(product_code)
WHERE is_active = TRUE;

-- Retail Sale: Business + Date (daily sales reports)
CREATE INDEX idx_retail_sale_business_date
ON retail_sale(business_id, sale_date DESC)
INCLUDE (total_amount, payment_method);

-- Retail Sale: Sale number lookup
CREATE INDEX idx_retail_sale_number
ON retail_sale(sale_number);

-- =============================================================================
-- LPG CYLINDER INDEXES
-- =============================================================================

-- LPG Cylinder: Serial number (unique lookup)
CREATE INDEX idx_lpg_cylinder_serial
ON retail_lpg_cylinder(serial_number);

-- LPG Cylinder: Business + Status (cylinder tracking)
CREATE INDEX idx_lpg_cylinder_business_status
ON retail_lpg_cylinder(business_id, status)
INCLUDE (brand, capacity_kg, current_location);

-- LPG Cylinder: Brand + Capacity (for exchange)
CREATE INDEX idx_lpg_cylinder_brand_capacity
ON retail_lpg_cylinder(brand, capacity_kg)
WHERE status = 'full';

-- =============================================================================
-- CUSTOMER INDEXES
-- =============================================================================

-- Customer: Phone number (unique, primary lookup)
CREATE INDEX idx_customer_phone
ON customer(phone_number)
WHERE is_active = TRUE;

-- Customer: Name search
CREATE INDEX idx_customer_name_gin
ON customer USING gin(to_tsvector('english', name));

-- Customer: Type lookup
CREATE INDEX idx_customer_type
ON customer(customer_type)
WHERE is_active = TRUE;

-- =============================================================================
-- AUDIT LOG INDEXES
-- =============================================================================

-- Audit Log: Table + Record (track specific record changes)
CREATE INDEX idx_audit_log_table_record
ON audit_log(table_name, record_id, created_at DESC)
INCLUDE (action, changed_by);

-- Audit Log: Business + Date (audit reports)
CREATE INDEX idx_audit_log_business_date
ON audit_log(business_id, created_at DESC)
INCLUDE (table_name, action, changed_by)
WHERE business_id IS NOT NULL;

-- Audit Log: User + Date (user activity tracking)
CREATE INDEX idx_audit_log_user_date
ON audit_log(changed_by, created_at DESC)
INCLUDE (table_name, action);

-- Audit Log: Action + Date (filter by action type)
CREATE INDEX idx_audit_log_action_date
ON audit_log(action, created_at DESC);

-- BRIN index for large-scale audit log (after > 1M rows)
CREATE INDEX idx_audit_log_date_brin
ON audit_log USING BRIN(created_at);

-- =============================================================================
-- USER MANAGEMENT INDEXES
-- =============================================================================

-- User: Email (unique, login lookup)
CREATE INDEX idx_user_email
ON user(email)
WHERE is_active = TRUE;

-- User: Phone number (unique, M-Pesa integration)
CREATE INDEX idx_user_phone
ON user(phone_number);

-- Business Access: User + Business (authorization checks)
CREATE INDEX idx_business_access_user_business
ON business_access(user_id, business_id)
INCLUDE (permission);

-- =============================================================================
-- MULTICOLUMN INDEXES FOR COMPLEX QUERIES
-- =============================================================================

-- Dashboard: Business + Date + Type (comprehensive dashboard query)
CREATE INDEX idx_dashboard_business_date_type
ON ledger(business_id, transaction_date DESC, transaction_type_id)
INCLUDE (is_debit, amount);

-- Account Balance: Account + Business + Date
CREATE INDEX idx_account_balance_account_business_date
ON account_balance(account_id, business_id, balance_date DESC)
INCLUDE (closing_balance, total_debits, total_credits);

-- Reconciliation: Account + Business + Date + Status
CREATE INDEX idx_reconciliation_account_business_date_status
ON reconciliation(account_id, business_id, reconciliation_date DESC)
INCLUDE (system_balance, external_balance, difference, status);

-- =============================================================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- =============================================================================

-- Only posted journal entries (exclude drafts and reversals)
CREATE INDEX idx_je_posted
ON journal_entry(business_id, transaction_date DESC)
WHERE status = 'posted';

-- Only active accounts
CREATE INDEX idx_account_active
ON account(account_number, business_id)
WHERE is_active = TRUE;

-- Only active products
CREATE INDEX idx_retail_product_active
ON retail_product(name, product_code)
WHERE is_active = TRUE;

-- Only active product sizes
CREATE INDEX idx_water_product_size_active
ON water_product_size(name, volume_ml)
WHERE is_active = TRUE;

-- =============================================================================
-- PERFORMANCE MONITORING
-- =============================================================================

-- Function: Check index usage
CREATE OR REPLACE FUNCTION check_index_usage()
RETURNS TABLE(
    schemaname TEXT,
    tablename TEXT,
    indexname TEXT,
    idx_scan BIGINT,
    idx_tup_read BIGINT,
    idx_tup_fetch BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pg_stat_user_indexes.schemaname,
        pg_stat_user_indexes.relname::TEXT AS tablename,
        pg_stat_user_indexes.indexrelname::TEXT AS indexname,
        pg_stat_user_indexes.idx_scan,
        pg_stat_user_indexes.idx_tup_read,
        pg_stat_user_indexes.idx_tup_fetch
    FROM pg_stat_user_indexes
    ORDER BY pg_stat_user_indexes.idx_scan ASC;
END;
$$ LANGUAGE plpgsql;

-- Function: Find missing indexes
CREATE OR REPLACE FUNCTION find_missing_indexes()
RETURNS TABLE(
    tablename TEXT,
    attname TEXT,
    n_distinct BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pg_stat_user_tables.relname::TEXT AS tablename,
        pg_stats.attname,
        pg_stats.n_distinct
    FROM pg_stat_user_tables
    JOIN pg_stats ON pg_stat_user_tables.relid = pg_stats.tablename
    WHERE pg_stat_user_tables.seq_scan > 1000  -- High sequential scans
      AND pg_stats.n_distinct > 100  -- High cardinality
      AND NOT EXISTS (
          SELECT 1 FROM pg_index
          WHERE pg_index.indrelid = pg_stat_user_tables.relid
            AND pg_stats.attnum = ANY(pg_index.indkey)
      )
    ORDER BY pg_stat_user_tables.seq_scan DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEX MAINTENANCE
-- =============================================================================

-- Reindex specific index (run during low traffic)
-- REINDEX INDEX CONCURRENTLY idx_ledger_account_date;

-- Reindex all indexes on a table
-- REINDEX TABLE CONCURRENTLY ledger;

-- Analyze table statistics (run after bulk inserts)
ANALYZE journal_entry;
ANALYZE ledger;
ANALYZE water_sale;
ANALYZE retail_sale;
ANALYZE laundry_job;

-- Vacuum to reclaim space (run weekly)
VACUUM ANALYZE;

-- =============================================================================
-- QUERY PERFORMANCE TIPS
-- =============================================================================

/*
1. USE EXPLAIN ANALYZE
   - Check query execution plan
   - Identify sequential scans
   - Verify index usage

2. AVOID FUNCTION CALLS IN WHERE CLAUSE
   - BAD: WHERE DATE(created_at) = '2026-01-28'
   - GOOD: WHERE created_at >= '2026-01-28' AND created_at < '2026-01-29'

3. USE PARTIAL INDEXES FOR FILTERED DATA
   - Reduces index size
   - Faster queries
   - Lower maintenance overhead

4. MONITOR INDEX USAGE
   - Remove unused indexes
   - They slow down INSERT/UPDATE/DELETE
   - Run check_index_usage() monthly

5. CONSIDER COVERING INDEXES (INCLUDE)
   - Include frequently accessed columns
   - Avoids table lookups
   - Improves query performance

6. USE BRIN INDEXES FOR TIME-SERIES
   - Smaller than B-tree
   - Good for large tables (> 1M rows)
   - Use for date columns

7. PARTITION LARGE TABLES
   - Partition ledger by year (when > 10M rows)
   - Partition audit_log by year (when > 10M rows)
   - Improves query performance
   - Easier to archive old data
*/

-- =============================================================================
-- END OF INDEXING STRATEGY
-- =============================================================================

-- Total Indexes: 70+
-- Estimated Index Storage: ~500 MB (Year 1)
-- Maintenance: Reindex monthly, Analyze weekly, Vacuum weekly

-- Performance Target:
- API response time: < 500ms
- Dashboard load: < 3 seconds on 4G
- Transaction recording: < 1 second
- Support 500+ transactions/day

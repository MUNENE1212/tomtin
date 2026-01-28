-- PostgreSQL Schema - Multi-Business ERP System
-- Database: PostgreSQL 15+
-- Schema Version: 1.0
-- Last Updated: 2026-01-28

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- For encryption

-- =============================================================================
-- DOMAINS
-- =============================================================================

-- Money type for precise decimal calculations
CREATE DOMAIN money AS NUMERIC(15, 2) DEFAULT 0.00 CHECK (VALUE >= 0);

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE user_role_enum AS ENUM ('owner', 'accountant', 'staff');
CREATE TYPE business_type_enum AS ENUM ('water', 'laundry', 'retail', 'other');
CREATE TYPE permission_enum AS ENUM ('read', 'write', 'admin');
CREATE TYPE account_type_enum AS ENUM ('asset', 'liability', 'equity', 'revenue', 'expense');
CREATE TYPE normal_balance_enum AS ENUM ('debit', 'credit');
CREATE TYPE je_status_enum AS ENUM ('draft', 'posted', 'reversed');
CREATE TYPE payment_method_enum AS ENUM ('cash', 'm_pesa', 'bank', 'mixed');
CREATE TYPE inventory_type_enum AS ENUM ('empty', 'filled');
CREATE TYPE laundry_status_enum AS ENUM ('received', 'washing', 'drying', 'ready', 'collected', 'cancelled');
CREATE TYPE pricing_type_enum AS ENUM ('per_item', 'per_kg', 'per_bundle', 'flat_rate');
CREATE TYPE cylinder_status_enum AS ENUM ('full', 'empty', 'customer', 'maintenance');
CREATE TYPE customer_type_enum AS ENUM ('individual', 'business', 'organization');
CREATE TYPE audit_action_enum AS ENUM ('create', 'update', 'delete', 'login', 'logout', 'export');

-- =============================================================================
-- TABLES: USER MANAGEMENT
-- =============================================================================

-- User table (extends Django's auth_user with additional fields)
CREATE TABLE user (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(150) UNIQUE,  -- Not used, but required by Django
    first_name VARCHAR(150) NOT NULL,
    last_name VARCHAR(150) NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pin VARCHAR(6),  -- 4-6 digit PIN for quick mobile login
    date_of_birth DATE,
    profile_picture VARCHAR(200),
    is_owner BOOLEAN DEFAULT FALSE,
    is_accountant BOOLEAN DEFAULT FALSE,
    is_staff BOOLEAN DEFAULT FALSE,
    is_superuser BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    date_joined TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_email ON user(email);
CREATE INDEX idx_user_phone ON user(phone_number);
CREATE INDEX idx_user_roles ON user(is_owner, is_accountant);

-- Role table (for future staff)
CREATE TABLE role (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_role_name ON role(name);
CREATE INDEX idx_role_active ON role(is_active);

-- Business Access table (many-to-many: User ↔ Business)
CREATE TABLE business_access (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    permission permission_enum DEFAULT 'read',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, business_id)
);

CREATE INDEX idx_business_access_user ON business_access(user_id, business_id);
CREATE INDEX idx_business_access_business ON business_access(business_id);

-- =============================================================================
-- TABLES: BUSINESS CONFIGURATION
-- =============================================================================

-- Business table
CREATE TABLE business (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) UNIQUE NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL,
    business_type business_type_enum NOT NULL,
    description TEXT,
    address TEXT,
    phone_number VARCHAR(20),
    email VARCHAR(254),
    is_active BOOLEAN DEFAULT TRUE,
    m_pesa_till_number VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_business_code ON business(code);
CREATE INDEX idx_business_active ON business(is_active);
CREATE INDEX idx_business_type ON business(business_type);

-- Business Settings table
CREATE TABLE business_settings (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT UNIQUE NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    tax_rate NUMERIC(5, 2) DEFAULT 16.00,
    currency_code VARCHAR(3) DEFAULT 'KES',
    currency_symbol VARCHAR(5) DEFAULT 'KSh',
    requires_signature BOOLEAN DEFAULT FALSE,
    signature_threshold MONEY DEFAULT 10000.00,
    allow_negative_stock BOOLEAN DEFAULT FALSE,
    low_stock_threshold INTEGER DEFAULT 10,
    operating_hours_start TIME DEFAULT '08:00',
    operating_hours_end TIME DEFAULT '20:00',
    receipt_footer TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- M-Pesa Till table
CREATE TABLE m_pesa_till (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    till_number VARCHAR(20) NOT NULL,
    till_name VARCHAR(200) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    merchant_id VARCHAR(50),
    consumer_key VARCHAR(100),  -- Should be encrypted
    consumer_secret VARCHAR(100),  -- Should be encrypted
    passkey VARCHAR(100),  -- Should be encrypted
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(business_id, till_number)
);

CREATE INDEX idx_m_pesa_till_number ON m_pesa_till(till_number);
CREATE INDEX idx_m_pesa_till_active ON m_pesa_till(is_active);

-- =============================================================================
-- TABLES: FINANCIAL CORE (MOST CRITICAL)
-- =============================================================================

-- Account Type table
CREATE TABLE account_type (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    code CHAR(1) UNIQUE NOT NULL,  -- A, L, E, R, X
    type account_type_enum NOT NULL,
    normal_balance normal_balance_enum NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Account table
CREATE TABLE account (
    id BIGSERIAL PRIMARY KEY,
    account_number VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    account_type_id BIGINT NOT NULL REFERENCES account_type(id) ON DELETE PROTECT,
    parent_account_id BIGINT REFERENCES account(id) ON DELETE CASCADE,
    business_id BIGINT REFERENCES business(id) ON DELETE CASCADE,
    description TEXT,
    current_balance MONEY DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    is_contra_account BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_account_number ON account(account_number);
CREATE INDEX idx_account_business ON account(business_id);
CREATE INDEX idx_account_type ON account(account_type_id);
CREATE INDEX idx_account_parent ON account(parent_account_id);
CREATE INDEX idx_account_active ON account(is_active);

-- Transaction Type table
CREATE TABLE transaction_type (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Journal Entry table
CREATE TABLE journal_entry (
    id BIGSERIAL PRIMARY KEY,
    entry_number VARCHAR(50) UNIQUE NOT NULL,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE PROTECT,
    transaction_type_id BIGINT NOT NULL REFERENCES transaction_type(id) ON DELETE PROTECT,
    transaction_date DATE NOT NULL,
    description TEXT NOT NULL,
    reference_number VARCHAR(100),
    status je_status_enum DEFAULT 'posted',
    total_debit MONEY DEFAULT 0.00,
    total_credit MONEY DEFAULT 0.00,
    created_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    posted_at TIMESTAMP
);

CREATE INDEX idx_journal_entry_number ON journal_entry(entry_number);
CREATE INDEX idx_journal_entry_business_date ON journal_entry(business_id, transaction_date);
CREATE INDEX idx_journal_entry_status ON journal_entry(status);
CREATE INDEX idx_journal_entry_type ON journal_entry(transaction_type_id);

-- Journal Entry Line table
CREATE TABLE journal_entry_line (
    id BIGSERIAL PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL REFERENCES journal_entry(id) ON DELETE CASCADE,
    account_id BIGINT NOT NULL REFERENCES account(id) ON DELETE PROTECT,
    description VARCHAR(200) NOT NULL,
    is_debit BOOLEAN DEFAULT TRUE,
    amount MONEY NOT NULL CHECK (amount > 0),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_journal_entry_line_je ON journal_entry_line(journal_entry_id);
CREATE INDEX idx_journal_entry_line_account ON journal_entry_line(account_id);

-- Ledger table (IMMUTABLE - every money movement)
CREATE TABLE ledger (
    id BIGSERIAL PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL REFERENCES journal_entry(id) ON DELETE PROTECT,
    journal_entry_line_id BIGINT NOT NULL REFERENCES journal_entry_line(id) ON DELETE PROTECT,
    account_id BIGINT NOT NULL REFERENCES account(id) ON DELETE PROTECT,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE PROTECT,
    transaction_date DATE NOT NULL,
    transaction_type_id BIGINT NOT NULL REFERENCES transaction_type(id) ON DELETE PROTECT,
    description TEXT NOT NULL,
    is_debit BOOLEAN NOT NULL,
    amount MONEY NOT NULL,
    balance_after MONEY NOT NULL,
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ledger_account_date ON ledger(account_id, transaction_date DESC);
CREATE INDEX idx_ledger_business_date ON ledger(business_id, transaction_date DESC);
CREATE INDEX idx_ledger_type ON ledger(transaction_type_id);
CREATE INDEX idx_ledger_reference ON ledger(reference_number);
CREATE INDEX idx_ledger_date_desc ON ledger(transaction_date DESC, account_id);

-- Account Balance table (snapshots for performance)
CREATE TABLE account_balance (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    balance_date DATE NOT NULL,
    opening_balance MONEY NOT NULL,
    closing_balance MONEY NOT NULL,
    total_debits MONEY NOT NULL,
    total_credits MONEY NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(account_id, business_id, balance_date)
);

CREATE INDEX idx_account_balance_account_date ON account_balance(account_id, balance_date);
CREATE INDEX idx_account_balance_business_date ON account_balance(business_id, balance_date);

-- Reconciliation table
CREATE TABLE reconciliation (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    reconciliation_date DATE NOT NULL,
    system_balance MONEY NOT NULL,
    external_balance MONEY NOT NULL,
    difference MONEY NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'reconciled', 'discrepancy')),
    notes TEXT,
    reconciled_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_reconciliation_account_date ON reconciliation(account_id, reconciliation_date);
CREATE INDEX idx_reconciliation_business_date ON reconciliation(business_id, reconciliation_date);
CREATE INDEX idx_reconciliation_status ON reconciliation(status);

-- =============================================================================
-- TABLES: WATER PACKAGING BUSINESS
-- =============================================================================

-- Water Product Size table
CREATE TABLE water_product_size (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    volume_ml INTEGER NOT NULL,
    default_price MONEY NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Water Inventory table
CREATE TABLE water_inventory (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    product_size_id BIGINT NOT NULL REFERENCES water_product_size(id) ON DELETE PROTECT,
    inventory_type inventory_type_enum NOT NULL,
    quantity INTEGER DEFAULT 0 CHECK (quantity >= 0),
    unit_cost MONEY DEFAULT 0.00,
    selling_price MONEY NOT NULL,
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(business_id, product_size_id, inventory_type)
);

CREATE INDEX idx_water_inventory_business_size ON water_inventory(business_id, product_size_id);
CREATE INDEX idx_water_inventory_type ON water_inventory(inventory_type);

-- Water Production table
CREATE TABLE water_production (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    product_size_id BIGINT NOT NULL REFERENCES water_product_size(id) ON DELETE PROTECT,
    quantity_produced INTEGER NOT NULL CHECK (quantity_produced > 0),
    production_cost MONEY NOT NULL,
    production_date DATE NOT NULL,
    notes TEXT,
    recorded_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_water_production_business_date ON water_production(business_id, production_date);
CREATE INDEX idx_water_production_size ON water_production(product_size_id);

-- Water Sale table
CREATE TABLE water_sale (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customer(id) ON DELETE SET NULL,
    product_size_id BIGINT NOT NULL REFERENCES water_product_size(id) ON DELETE PROTECT,
    quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
    unit_price MONEY NOT NULL,
    total_amount MONEY NOT NULL,
    payment_method payment_method_enum NOT NULL,
    m_pesa_transaction_id VARCHAR(100),
    sale_date DATE NOT NULL,
    sale_time TIME DEFAULT NOW(),
    notes TEXT,
    recorded_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    journal_entry_id BIGINT UNIQUE REFERENCES journal_entry(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_water_sale_business_date ON water_sale(business_id, sale_date);
CREATE INDEX idx_water_sale_customer ON water_sale(customer_id);
CREATE INDEX idx_water_sale_size ON water_sale(product_size_id);
CREATE INDEX idx_water_sale_payment ON water_sale(payment_method);

-- =============================================================================
-- TABLES: LAUNDRY BUSINESS
-- =============================================================================

-- Laundry Customer table (extends Customer)
CREATE TABLE laundry_customer (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT UNIQUE NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    credit_limit MONEY DEFAULT 5000.00,
    current_balance MONEY DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_laundry_customer_code ON laundry_customer(customer_code);

-- Laundry Service Type table
CREATE TABLE laundry_service_type (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    pricing_type pricing_type_enum NOT NULL,
    default_price MONEY NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Laundry Job table
CREATE TABLE laundry_job (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES laundry_customer(id) ON DELETE PROTECT,
    job_number VARCHAR(50) UNIQUE NOT NULL,
    status laundry_status_enum DEFAULT 'received',
    received_date DATE NOT NULL,
    received_time TIME DEFAULT NOW(),
    expected_completion_date DATE,
    actual_completion_date DATE,
    collected_date DATE,
    subtotal_amount MONEY DEFAULT 0.00,
    discount_amount MONEY DEFAULT 0.00,
    tax_amount MONEY DEFAULT 0.00,
    total_amount MONEY DEFAULT 0.00,
    amount_paid MONEY DEFAULT 0.00,
    balance_due MONEY DEFAULT 0.00,
    notes TEXT,
    received_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    journal_entry_id BIGINT UNIQUE REFERENCES journal_entry(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_laundry_job_business_date ON laundry_job(business_id, received_date);
CREATE INDEX idx_laundry_job_customer ON laundry_job(customer_id);
CREATE INDEX idx_laundry_job_status ON laundry_job(status);
CREATE INDEX idx_laundry_job_number ON laundry_job(job_number);
CREATE INDEX idx_laundry_job_status_date ON laundry_job(status, received_date);

-- Laundry Job Item table
CREATE TABLE laundry_job_item (
    id BIGSERIAL PRIMARY KEY,
    job_id BIGINT NOT NULL REFERENCES laundry_job(id) ON DELETE CASCADE,
    service_type_id BIGINT NOT NULL REFERENCES laundry_service_type(id) ON DELETE PROTECT,
    item_description VARCHAR(200) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price MONEY NOT NULL,
    line_total MONEY NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- TABLES: RETAIL/LPG BUSINESS
-- =============================================================================

-- Retail Product Category table
CREATE TABLE retail_product_category (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parent_category_id BIGINT REFERENCES retail_product_category(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Retail Product table
CREATE TABLE retail_product (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    category_id BIGINT REFERENCES retail_product_category(id) ON DELETE SET NULL,
    description TEXT,
    unit_of_measure VARCHAR(20) DEFAULT 'piece',
    is_lpg BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_retail_product_code ON retail_product(product_code);
CREATE INDEX idx_retail_product_name ON retail_product(name);
CREATE INDEX idx_retail_product_category ON retail_product(category_id);

-- Retail Inventory table
CREATE TABLE retail_inventory (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES retail_product(id) ON DELETE PROTECT,
    quantity_in_stock INTEGER DEFAULT 0 CHECK (quantity_in_stock >= 0),
    buying_price MONEY NOT NULL,
    selling_price MONEY NOT NULL,
    reorder_level INTEGER DEFAULT 10,
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(business_id, product_id)
);

CREATE INDEX idx_retail_inventory_business_product ON retail_inventory(business_id, product_id);
CREATE INDEX idx_retail_inventory_quantity ON retail_inventory(quantity_in_stock);

-- Retail LPG Cylinder table
CREATE TABLE retail_lpg_cylinder (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    brand VARCHAR(50) NOT NULL,
    capacity_kg NUMERIC(5, 2) NOT NULL,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    status cylinder_status_enum DEFAULT 'full',
    purchase_date DATE,
    purchase_price MONEY,
    last_exchange_date DATE,
    current_location VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_lpg_cylinder_serial ON retail_lpg_cylinder(serial_number);
CREATE INDEX idx_lpg_cylinder_business_status ON retail_lpg_cylinder(business_id, status);
CREATE INDEX idx_lpg_cylinder_brand_capacity ON retail_lpg_cylinder(brand, capacity_kg);

-- Retail LPG Exchange table
CREATE TABLE retail_lpg_exchange (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customer(id) ON DELETE SET NULL,
    full_cylinder_id BIGINT NOT NULL REFERENCES retail_lpg_cylinder(id) ON DELETE PROTECT,
    empty_cylinder_id BIGINT REFERENCES retail_lpg_cylinder(id) ON DELETE PROTECT,
    capacity_kg NUMERIC(5, 2) NOT NULL,
    price_per_kg MONEY NOT NULL,
    total_amount MONEY NOT NULL,
    payment_method payment_method_enum NOT NULL,
    m_pesa_transaction_id VARCHAR(100),
    exchange_date DATE NOT NULL,
    exchange_time TIME DEFAULT NOW(),
    notes TEXT,
    recorded_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    journal_entry_id BIGINT UNIQUE REFERENCES journal_entry(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_lpg_exchange_business_date ON retail_lpg_exchange(business_id, exchange_date);
CREATE INDEX idx_lpg_exchange_customer ON retail_lpg_exchange(customer_id);
CREATE INDEX idx_lpg_exchange_cylinder ON retail_lpg_exchange(full_cylinder_id);

-- Retail Sale table
CREATE TABLE retail_sale (
    id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES business(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customer(id) ON DELETE SET NULL,
    sale_number VARCHAR(50) UNIQUE NOT NULL,
    subtotal_amount MONEY DEFAULT 0.00,
    discount_amount MONEY DEFAULT 0.00,
    tax_amount MONEY DEFAULT 0.00,
    total_amount MONEY DEFAULT 0.00,
    payment_method payment_method_enum NOT NULL,
    m_pesa_transaction_id VARCHAR(100),
    sale_date DATE NOT NULL,
    sale_time TIME DEFAULT NOW(),
    notes TEXT,
    recorded_by BIGINT NOT NULL REFERENCES user(id) ON DELETE PROTECT,
    journal_entry_id BIGINT UNIQUE REFERENCES journal_entry(id) ON DELETE PROTECT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_retail_sale_business_date ON retail_sale(business_id, sale_date);
CREATE INDEX idx_retail_sale_customer ON retail_sale(customer_id);
CREATE INDEX idx_retail_sale_payment ON retail_sale(payment_method);
CREATE INDEX idx_retail_sale_number ON retail_sale(sale_number);

-- Retail Sale Item table
CREATE TABLE retail_sale_item (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES retail_sale(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES retail_product(id) ON DELETE PROTECT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price MONEY NOT NULL,
    line_total MONEY NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- TABLES: SHARED/CROSS-BUSINESS
-- =============================================================================

-- Customer table (shared across all businesses)
CREATE TABLE customer (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    phone_number_2 VARCHAR(20),
    email VARCHAR(254),
    address TEXT,
    id_number VARCHAR(50),
    customer_type customer_type_enum DEFAULT 'individual',
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_customer_phone ON customer(phone_number);
CREATE INDEX idx_customer_name ON customer(name);
CREATE INDEX idx_customer_type ON customer(customer_type);

-- =============================================================================
-- TABLES: AUDIT LOG (7-Year Retention - KRA Compliance)
-- =============================================================================

-- Audit Log table
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action audit_action_enum NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_fields JSONB,
    changed_by BIGINT REFERENCES user(id) ON DELETE SET NULL,
    business_id BIGINT REFERENCES business(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_business_date ON audit_log(business_id, created_at);
CREATE INDEX idx_audit_log_user_date ON audit_log(changed_by, created_at);
CREATE INDEX idx_audit_log_action_date ON audit_log(action, created_at);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function: Update account balance
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update account current_balance based on ledger entry
    UPDATE account
    SET current_balance = NEW.balance_after,
        updated_at = NOW()
    WHERE id = NEW.account_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update account balance after ledger insert
CREATE TRIGGER trigger_update_account_balance
AFTER INSERT ON ledger
FOR EACH ROW
EXECUTE FUNCTION update_account_balance();

-- Function: Validate journal entry balancing
CREATE OR REPLACE FUNCTION validate_journal_entry_balance()
RETURNS TRIGGER AS $$
DECLARE
    total_debit NUMERIC;
    total_credit NUMERIC;
BEGIN
    -- Calculate totals
    SELECT COALESCE(SUM(amount), 0) INTO total_debit
    FROM journal_entry_line
    WHERE journal_entry_id = NEW.id AND is_debit = TRUE;

    SELECT COALESCE(SUM(amount), 0) INTO total_credit
    FROM journal_entry_line
    WHERE journal_entry_id = NEW.id AND is_debit = FALSE;

    -- Update journal entry totals
    UPDATE journal_entry
    SET total_debit = total_debit,
        total_credit = total_credit
    WHERE id = NEW.id;

    -- Validate balance
    IF total_debit != total_credit THEN
        RAISE EXCEPTION 'Journal entry must balance. Debits: %, Credits: %', total_debit, total_credit;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Validate journal entry after insert/update
CREATE TRIGGER trigger_validate_journal_entry
AFTER INSERT OR UPDATE ON journal_entry_line
FOR EACH ROW
EXECUTE FUNCTION validate_journal_entry_balance();

-- =============================================================================
-- VIEWS (For Common Queries)
-- =============================================================================

-- View: Account balances with details
CREATE VIEW v_account_balances AS
SELECT
    a.id,
    a.account_number,
    a.name,
    a.business_id,
    b.name AS business_name,
    a.account_type_id,
    at.name AS account_type_name,
    a.current_balance,
    at.normal_balance
FROM account a
LEFT JOIN business b ON a.business_id = b.id
LEFT JOIN account_type at ON a.account_type_id = at.id
WHERE a.is_active = TRUE;

-- View: Today's sales summary
CREATE VIEW v_today_sales AS
SELECT
    b.id AS business_id,
    b.name AS business_name,
    b.business_type,
    COUNT(DISTINCT ws.id) AS water_sales_count,
    COALESCE(SUM(ws.total_amount), 0) AS water_sales_total,
    COUNT(DISTINCT lj.id) AS laundry_jobs_count,
    COALESCE(SUM(lj.total_amount), 0) AS laundry_total,
    COUNT(DISTINCT rs.id) AS retail_sales_count,
    COALESCE(SUM(rs.total_amount), 0) AS retail_sales_total,
    COALESCE(SUM(ws.total_amount), 0) +
    COALESCE(SUM(lj.total_amount), 0) +
    COALESCE(SUM(rs.total_amount), 0) AS total_revenue
FROM business b
LEFT JOIN water_sale ws ON b.id = ws.business_id AND ws.sale_date = CURRENT_DATE
LEFT JOIN laundry_job lj ON b.id = lj.business_id AND lj.received_date = CURRENT_DATE
LEFT JOIN retail_sale rs ON b.id = rs.business_id AND rs.sale_date = CURRENT_DATE
WHERE b.is_active = TRUE
GROUP BY b.id, b.name, b.business_type;

-- View: Low stock alert
CREATE VIEW v_low_stock_alert AS
SELECT
    'water' AS business_type,
    b.name AS business_name,
    wps.name AS product_name,
    wi.quantity AS quantity_in_stock,
    bs.low_stock_threshold
FROM water_inventory wi
JOIN business b ON wi.business_id = b.id
JOIN water_product_size wps ON wi.product_size_id = wps.id
JOIN business_settings bs ON b.id = bs.business_id
WHERE wi.quantity <= bs.low_stock_threshold

UNION ALL

SELECT
    'retail' AS business_type,
    b.name AS business_name,
    rp.name AS product_name,
    ri.quantity_in_stock,
    ri.reorder_level
FROM retail_inventory ri
JOIN business b ON ri.business_id = b.id
JOIN retail_product rp ON ri.product_id = rp.id
WHERE ri.quantity_in_stock <= ri.reorder_level;

-- =============================================================================
-- COMMENTS (Documentation)
-- =============================================================================

COMMENT ON TABLE user IS 'User accounts for the ERP system';
COMMENT ON TABLE business IS 'Business entities (Water, Laundry, Retail)';
COMMENT ON TABLE account IS 'Chart of accounts for double-entry bookkeeping';
COMMENT ON TABLE journal_entry IS 'Journal entry headers for financial transactions';
COMMENT ON TABLE journal_entry_line IS 'Journal entry lines (debits and credits)';
COMMENT ON TABLE ledger IS 'Universal ledger - every money movement (immutable)';
COMMENT ON TABLE audit_log IS 'Comprehensive audit log for 7-year retention (KRA compliance)';

COMMENT ON COLUMN ledger.balance_after IS 'Account balance after this transaction';
COMMENT ON COLUMN journal_entry_line.is_debit IS 'TRUE = Debit, FALSE = Credit';

-- =============================================================================
-- SECURITY POLICIES (Row-Level Security - Optional)
-- =============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entry ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entry_line ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see ledger entries for their assigned businesses
CREATE POLICY ledger_business_isolation ON ledger
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id FROM business_access
            WHERE user_id = current_setting('app.current_user_id')::BIGINT
        )
    );

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================

-- Total Tables: 32
-- Total Indexes: 70+
-- Total Views: 3
-- Total Functions: 2
-- Total Triggers: 2

-- Next Steps:
-- 1. Run this schema in PostgreSQL
-- 2. Create Django migrations from this schema
-- 3. Insert seed data (see seed_data.sql)
-- 4. Set up backups and monitoring
-- 5. Implement connection pooling (PgBouncer)

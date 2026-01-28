-- Seed Data - Multi-Business ERP System
-- Purpose: Initial data for testing and development
-- Last Updated: 2026-01-28

-- =============================================================================
-- BEGIN TRANSACTION
-- =============================================================================

BEGIN;

-- =============================================================================
-- ACCOUNT TYPES (Chart of Accounts Structure)
-- =============================================================================

INSERT INTO account_type (id, name, code, type, normal_balance, description) VALUES
(1, 'Assets', 'A', 'asset', 'debit', 'Resources owned by the business'),
(2, 'Liabilities', 'L', 'liability', 'credit', 'Obligations owed by the business'),
(3, 'Equity', 'E', 'equity', 'credit', 'Owner''s investment in the business'),
(4, 'Revenue', 'R', 'revenue', 'credit', 'Income from business operations'),
(5, 'Expenses', 'X', 'expense', 'debit', 'Costs incurred in operations');

-- =============================================================================
-- TRANSACTION TYPES
-- =============================================================================

INSERT INTO transaction_type (name, code, description, is_active) VALUES
('Sale', 'SALE', 'Sales revenue from goods or services', TRUE),
('Expense', 'EXP', 'Business expense payment', TRUE),
('Deposit', 'DEP', 'Deposit cash or M-Pesa to bank account', TRUE),
('Withdrawal', 'WD', 'Withdraw from bank or owner drawing', TRUE),
('Transfer', 'TRF', 'Transfer between accounts', TRUE),
('Adjustment', 'ADJ', 'Accounting adjustment (requires approval)', TRUE),
('Payment Received', 'PAY', 'Payment received from customer', TRUE);

-- =============================================================================
-- BUSINESSES
-- =============================================================================

INSERT INTO business (id, name, code, business_type, description, phone_number, is_active, m_pesa_till_number) VALUES
(1, 'Water Packaging Business', 'WTR', 'water', 'Production and sale of packaged water', '+254700000001', TRUE, '174111'),
(2, 'Laundry Business', 'LND', 'laundry', 'Laundry and dry cleaning services', '+254700000002', TRUE, '174222'),
(3, 'Retail Shop', 'RTL', 'retail', 'Retail shop including LPG gas sales', '+254700000003', TRUE, '174333');

-- =============================================================================
-- BUSINESS SETTINGS
-- =============================================================================

INSERT INTO business_settings (business_id, tax_rate, currency_code, currency_symbol, requires_signature, signature_threshold, allow_negative_stock, low_stock_threshold, operating_hours_start, operating_hours_end) VALUES
(1, 16.00, 'KES', 'KSh', FALSE, 10000.00, FALSE, 50, '08:00', '20:00'),
(2, 16.00, 'KES', 'KSh', FALSE, 10000.00, FALSE, 10, '08:00', '20:00'),
(3, 16.00, 'KES', 'KSh', FALSE, 10000.00, FALSE, 20, '08:00', '20:00');

-- =============================================================================
-- CHART OF ACCOUNTS (Shared Accounts)
-- =============================================================================

-- Owner Capital & Equity
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('3100', 'Owner''s Capital', 3, NULL, NULL, 0.00, TRUE),
('3200', 'Owner''s Drawings', 3, NULL, NULL, 0.00, TRUE),
('3300', 'Retained Earnings', 3, NULL, NULL, 0.00, TRUE);

-- Bank Accounts (Shared)
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('1170', 'Cooperative Bank Account', 1, NULL, NULL, 50000.00, TRUE),
('1171', 'Equity Bank Account', 1, NULL, NULL, 30000.00, TRUE);

-- Accounts Payable (Shared)
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('2110', 'Accounts Payable', 2, NULL, NULL, 0.00, TRUE),
('2120', 'M-Pesa Payable', 2, NULL, NULL, 0.00, TRUE);

-- =============================================================================
-- CHART OF ACCOUNTS (Water Business)
-- =============================================================================

-- Assets
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('1110', 'Cash - Water', 1, NULL, 1, 5000.00, TRUE),
('1140', 'M-Pesa - Water', 1, NULL, 1, 8000.00, TRUE),
('1210', 'Water Inventory', 1, NULL, 1, 15000.00, TRUE);

-- Liabilities

-- Equity

-- Revenue
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('4100', 'Water Sales Revenue', 4, NULL, 1, 0.00, TRUE);

-- Expenses
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('5110', 'Water Production Cost', 5, NULL, 1, 0.00, TRUE);

-- =============================================================================
-- CHART OF ACCOUNTS (Laundry Business)
-- =============================================================================

-- Assets
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('1120', 'Cash - Laundry', 1, NULL, 2, 3000.00, TRUE),
('1141', 'M-Pesa - Laundry', 1, NULL, 2, 5000.00, TRUE);

-- Revenue
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('4200', 'Laundry Service Revenue', 4, NULL, 2, 0.00, TRUE);

-- Expenses
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('5210', 'Laundry Supplies Cost', 5, NULL, 2, 0.00, TRUE);

-- =============================================================================
-- CHART OF ACCOUNTS (Retail Business)
-- =============================================================================

-- Assets
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('1130', 'Cash - Retail', 1, NULL, 3, 4000.00, TRUE),
('1142', 'M-Pesa - Retail', 1, NULL, 3, 6000.00, TRUE),
('1220', 'Retail Inventory', 1, NULL, 3, 25000.00, TRUE),
('1230', 'LPG Cylinder Assets', 1, NULL, 3, 30000.00, TRUE);

-- Revenue
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('4300', 'Retail Sales Revenue', 4, NULL, 3, 0.00, TRUE),
('4310', 'LPG Sales Revenue', 4, NULL, 3, 0.00, TRUE);

-- Expenses
INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('5120', 'Cost of Goods Sold', 5, NULL, 3, 0.00, TRUE);

-- =============================================================================
-- SHARED EXPENSE ACCOUNTS
-- =============================================================================

INSERT INTO account (account_number, name, account_type_id, parent_account_id, business_id, current_balance, is_active) VALUES
('5200', 'Rent Expense', 5, NULL, NULL, 0.00, TRUE),
('5300', 'Utilities Expense', 5, NULL, NULL, 0.00, TRUE),
('5400', 'Salaries Expense', 5, NULL, NULL, 0.00, TRUE),
('5500', 'Transportation Expense', 5, NULL, NULL, 0.00, TRUE),
('5600', 'Marketing Expense', 5, NULL, NULL, 0.00, TRUE),
('5700', 'Maintenance Expense', 5, NULL, NULL, 0.00, TRUE),
('5800', 'Other Expenses', 5, NULL, NULL, 0.00, TRUE);

-- =============================================================================
-- WATER PRODUCT SIZES
-- =============================================================================

INSERT INTO water_product_size (name, volume_ml, default_price, is_active) VALUES
('500ml', 500, 20.00, TRUE),
('1 Litre', 1000, 30.00, TRUE),
('5 Litres', 5000, 100.00, TRUE),
('10 Litres', 10000, 180.00, TRUE),
('20 Litres', 20000, 350.00, TRUE);

-- =============================================================================
-- WATER INVENTORY (Initial Stock)
-- =============================================================================

-- Empty containers
INSERT INTO water_inventory (business_id, product_size_id, inventory_type, quantity, unit_cost, selling_price) VALUES
(1, 1, 'empty', 500, 8.00, 20.00),   -- 500ml
(1, 2, 'empty', 300, 12.00, 30.00),  -- 1L
(1, 3, 'empty', 200, 40.00, 100.00), -- 5L
(1, 4, 'empty', 100, 80.00, 180.00), -- 10L
(1, 5, 'empty', 50, 150.00, 350.00); -- 20L

-- Filled products
INSERT INTO water_inventory (business_id, product_size_id, inventory_type, quantity, unit_cost, selling_price) VALUES
(1, 1, 'filled', 200, 12.00, 20.00),  -- 500ml
(1, 2, 'filled', 150, 18.00, 30.00),  -- 1L
(1, 3, 'filled', 100, 60.00, 100.00), -- 5L
(1, 4, 'filled', 50, 120.00, 180.00), -- 10L
(1, 5, 'filled', 20, 220.00, 350.00); -- 20L

-- =============================================================================
-- LAUNDRY SERVICE TYPES
-- =============================================================================

INSERT INTO laundry_service_type (name, description, pricing_type, default_price, is_active) VALUES
('Wash & Fold', 'Wash and fold laundry service', 'per_kg', 50.00, TRUE),
('Dry Cleaning', 'Dry cleaning service', 'per_item', 150.00, TRUE),
('Ironing', 'Ironing service only', 'per_item', 30.00, TRUE),
('Wash & Iron', 'Wash and iron service', 'per_item', 80.00, TRUE),
('Bedding', 'Bedding and linen cleaning', 'per_bundle', 200.00, TRUE),
('Suit Cleaning', 'Suit dry cleaning', 'per_item', 300.00, TRUE),
('Duvet Cleaning', 'Duvet and comforter cleaning', 'per_item', 400.00, TRUE);

-- =============================================================================
-- RETAIL PRODUCT CATEGORIES
-- =============================================================================

INSERT INTO retail_product_category (name, description) VALUES
('Beverages', 'Soft drinks, juices, water'),
('Snacks', 'Chips, biscuits, nuts'),
('Household', 'Cleaning supplies, toiletries'),
('LPG Gas', 'LPG gas cylinders and refills'),
('Dairy', 'Milk, yogurt, cheese'),
('Grains', 'Rice, flour, cereals');

-- =============================================================================
-- RETAIL PRODUCTS
-- =============================================================================

INSERT INTO retail_product (name, product_code, category_id, description, unit_of_measure, is_lpg, is_active) VALUES
('Coca Cola 500ml', 'BEV001', 1, 'Coca Cola soft drink 500ml', 'bottle', FALSE, TRUE),
('Sprite 500ml', 'BEV002', 1, 'Sprite soft drink 500ml', 'bottle', FALSE, TRUE),
('Kenchic Chips 100g', 'SNK001', 2, 'Kenchic potato chips 100g', 'packet', FALSE, TRUE),
('Milk 500ml', 'DAI001', 5, 'Fresh milk 500ml', 'packet', FALSE, TRUE),
('Sugar 1kg', 'GRN001', 6, 'White sugar 1kg', 'packet', FALSE, TRUE),
('Maize Flour 2kg', 'GRN002', 6, 'Maize meal flour 2kg', 'packet', FALSE, TRUE);

-- =============================================================================
-- RETAIL INVENTORY (Initial Stock)
-- =============================================================================

INSERT INTO retail_inventory (business_id, product_id, quantity_in_stock, buying_price, selling_price, reorder_level) VALUES
(3, 1, 100, 35.00, 50.00, 20),   -- Coca Cola
(3, 2, 80, 35.00, 50.00, 20),    -- Sprite
(3, 3, 50, 40.00, 60.00, 15),    -- Chips
(3, 4, 60, 55.00, 70.00, 20),    -- Milk
(3, 5, 40, 120.00, 150.00, 10),  -- Sugar
(3, 6, 35, 130.00, 160.00, 10);  -- Maize Flour

-- =============================================================================
-- LPG CYLINDERS (Initial Stock)
-- =============================================================================

-- Shell 6kg cylinders
INSERT INTO retail_lpg_cylinder (business_id, brand, capacity_kg, serial_number, status, purchase_date, purchase_price) VALUES
(3, 'Shell', 6.0, 'SH6-0001', 'full', '2025-01-01', 2500.00),
(3, 'Shell', 6.0, 'SH6-0002', 'full', '2025-01-01', 2500.00),
(3, 'Shell', 6.0, 'SH6-0003', 'full', '2025-01-01', 2500.00),
(3, 'Shell', 6.0, 'SH6-0004', 'full', '2025-01-01', 2500.00),
(3, 'Shell', 6.0, 'SH6-0005', 'full', '2025-01-01', 2500.00);

-- Shell 13kg cylinders
INSERT INTO retail_lpg_cylinder (business_id, brand, capacity_kg, serial_number, status, purchase_date, purchase_price) VALUES
(3, 'Shell', 13.0, 'SH13-0001', 'full', '2025-01-01', 4500.00),
(3, 'Shell', 13.0, 'SH13-0002', 'full', '2025-01-01', 4500.00),
(3, 'Shell', 13.0, 'SH13-0003', 'full', '2025-01-01', 4500.00);

-- Total 6kg cylinders: 5
-- Total 13kg cylinders: 3
-- Total cylinder asset value: 5*2500 + 3*4500 = 12,500 + 13,500 = 26,000

-- =============================================================================
-- SAMPLE CUSTOMERS
-- =============================================================================

INSERT INTO customer (name, phone_number, phone_number_2, email, address, customer_type, is_active) VALUES
('John Kamau', '+254711000001', NULL, 'john@example.com', 'Nairobi', 'individual', TRUE),
('Mary Wanjiku', '+254722000002', NULL, 'mary@example.com', 'Nairobi', 'individual', TRUE),
('Peter Omondi', '+254733000003', NULL, 'peter@example.com', 'Nairobi', 'individual', TRUE),
('ABC Company Ltd', '+254744000004', '+254744000005', 'info@abc.co.ke', 'Industrial Area', 'business', TRUE),
('Grace Njeri', '+254755000006', NULL, NULL, 'Nairobi', 'individual', TRUE);

-- =============================================================================
-- LAUNDRY CUSTOMERS (Extended profiles)
-- =============================================================================

INSERT INTO laundry_customer (customer_id, customer_code, credit_limit, current_balance) VALUES
(1, 'LC001', 5000.00, 0.00),
(2, 'LC002', 3000.00, 0.00),
(5, 'LC003', 2000.00, 0.00);

-- =============================================================================
-- ROLES (For Future Staff)
-- =============================================================================

INSERT INTO role (name, description, permissions, is_active) VALUES
('Owner', 'Full system access', '{"all": true}', TRUE),
('Accountant', 'Financial management', '{"finance": true, "operations": "read"}', TRUE),
('Cashier', 'Record sales', '{"sales": true, "reports": "read"}', TRUE),
('Manager', 'Business management', '{"all": true, "users": "read"}', TRUE);

-- =============================================================================
-- USERS (Will be created via Django createsuperuser)
-- =============================================================================

-- Owner user will be created via:
-- python manage.py createsuperuser --email owner@tomtin.com --phone_number +254700000000

-- After creation, update manually:
-- UPDATE user SET is_owner = TRUE WHERE email = 'owner@tomtin.com';

-- Insert business access for owner (after user creation)
-- INSERT INTO business_access (user_id, business_id, permission) VALUES
-- (1, 1, 'admin'),
-- (1, 2, 'admin'),
-- (1, 3, 'admin');

-- =============================================================================
-- SAMPLE JOURNAL ENTRY (First Transaction)
-- =============================================================================

-- This is just an example. In production, journal entries are created by the application.

-- INSERT INTO journal_entry (entry_number, business_id, transaction_type_id, transaction_date, description, total_debit, total_credit, created_by, status, posted_at) VALUES
-- ('JE-20260128-0001', 1, 1, CURRENT_DATE, 'Opening balance - Water business', 23000.00, 23000.00, 1, 'posted', NOW());

-- =============================================================================
-- COMMIT TRANSACTION
-- =============================================================================

COMMIT;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify businesses
SELECT id, name, code, business_type FROM business ORDER BY id;

-- Verify accounts
SELECT account_number, name, business_id FROM account ORDER BY account_number;

-- Verify water inventory
SELECT wi.business_id, wps.name AS size, wi.inventory_type, wi.quantity
FROM water_inventory wi
JOIN water_product_size wps ON wi.product_size_id = wps.id
ORDER BY wi.business_id, wps.volume_ml;

-- Verify retail inventory
SELECT ri.business_id, rp.name AS product, ri.quantity_in_stock, ri.selling_price
FROM retail_inventory ri
JOIN retail_product rp ON ri.product_id = rp.id
ORDER BY ri.business_id, rp.name;

-- Verify LPG cylinders
SELECT brand, capacity_kg, status, COUNT(*) AS count
FROM retail_lpg_cylinder
GROUP BY brand, capacity_kg, status
ORDER BY brand, capacity_kg;

-- Verify customers
SELECT id, name, phone_number, customer_type FROM customer ORDER BY id;

-- =============================================================================
-- END OF SEED DATA
-- =============================================================================

-- Total Records Inserted:
-- - Account types: 5
-- - Transaction types: 7
-- - Businesses: 3
-- - Business settings: 3
-- - Accounts: 30+
-- - Water product sizes: 5
-- - Water inventory: 10
-- - Laundry service types: 7
-- - Retail categories: 6
-- - Retail products: 6
-- - Retail inventory: 6
-- - LPG cylinders: 8
-- - Customers: 5
-- - Laundry customers: 3
-- - Roles: 4

-- Estimated Database Size After Seed: ~5 MB

-- Next Steps:
-- 1. Create owner user: python manage.py createsuperuser
-- 2. Assign business access to owner
-- 3. Test with sample transactions
-- 4. Verify double-entry bookkeeping
-- 5. Check account balances

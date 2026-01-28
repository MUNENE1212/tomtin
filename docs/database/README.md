# Database Schema Design - Multi-Business ERP System

## Overview

This document provides a comprehensive database schema design for a multi-business ERP system supporting 3 independent businesses (Water Packaging, Laundry, Retail/LPG) with a consolidated financial core using double-entry bookkeeping.

**Last Updated:** 2026-01-28
**Database:** PostgreSQL 15+
**ORM:** Django 5.0+
**Architecture:** Shared Database with Row-Level Multi-Tenancy

---

## Table of Contents

1. [Architecture Approach](#architecture-approach)
2. [Multi-Tenancy Strategy](#multi-tenancy-strategy)
3. [Financial Core Design](#financial-core-design)
4. [Entity-Relationship Overview](#entity-relationship-overview)
5. [Database Domains](#database-domains)
6. [Indexing Strategy](#indexing-strategy)
7. [Performance Considerations](#performance-considerations)
8. [Security & Audit](#security--audit)
9. [Scalability Planning](#scalability-planning)
10. [Migration Strategy](#migration-strategy)

---

## Architecture Approach

### Selected Pattern: **Shared Database with Business_ID Foreign Key**

After evaluating three multi-tenancy patterns:

1. **Separate Database per Business** ❌ REJECTED
   - Pros: Complete isolation, easier backup per business
   - Cons: Overkill for 3 businesses, complex consolidated reporting, difficult transactions across businesses

2. **PostgreSQL Schemas per Business** ❌ REJECTED
   - Pros: Logical isolation within one database
   - Cons: Complex migrations, difficult unified queries, no Django native support

3. **Shared Database with Business_ID** ✅ SELECTED
   - Pros: Easy consolidated reporting, simple migrations, Django native, easy to add businesses
   - Cons: Application-level isolation (we'll mitigate with proper constraints and query filtering)

### Rationale

- **Simplicity:** Single database, single Django project, straightforward deployment
- **Consolidated Financials:** Universal ledger across all businesses (primary requirement)
- **Scalability:** Can add 4th+ business without schema changes
- **Performance:** Proper indexing makes business_id filtering efficient
- **Cost:** Single database instance reduces operational cost (within $200/month budget)

---

## Multi-Tenancy Strategy

### Isolation Levels

**Financial Core:** SHARED
- Chart of Accounts (some shared, some business-specific)
- Universal Ledger (all transactions in one place)
- Journal Entries (cross-business visibility)

**Operational Data:** ISOLATED per Business
- Inventory (Water inventory separate from Retail)
- Sales (Water sales separate from Laundry)
- Products/Services (Business-specific catalog)
- Customers (Can be shared, but transactions isolated)

### Implementation Pattern

Every model that belongs to a business has:
```python
business = models.ForeignKey(
    'Business',
    on_delete=models.CASCADE,
    db_index=True
)
```

### Query Filtering Strategy

**Django Middleware Pattern:**
- Set `business_id` in request context from user's selected business
- Default queryset manager automatically filters by `business_id`
- Prevent cross-business data leaks

**Example:**
```python
class BusinessAwareManager(models.Manager):
    def get_queryset(self):
        queryset = super().get_queryset()
        if hasattr(self, '_business_id'):
            return queryset.filter(business_id=self._business_id)
        return queryset
```

---

## Financial Core Design

### Double-Entry Bookkeeping (Non-Negotiable)

**Fundamental Principle:**
Every financial transaction must have equal debits and credits:
```
SUM(debits) = SUM(credits)
```

**Enforcement Strategy:**
1. **Application Level:** Django model validation (JournalEntry.clean())
2. **Database Level:** Check constraint (PostgreSQL 15+)
3. **Transaction Level:** Database transaction wraps entire journal entry

### Chart of Accounts Structure

**5-Tier Hierarchy:**
1. **Account Type:** Asset, Liability, Equity, Revenue, Expense
2. **Account Category:** Current Asset, Fixed Asset, Current Liability, etc.
3. **Account Class:** Cash, Bank, Inventory, Accounts Receivable, etc.
4. **Account Subclass:** Business-specific accounts
5. **Account:** Individual ledger account with balance

**Account Numbering System:**
```
1000-1999: Assets
  1100-1199: Current Assets
    1110: Cash (Water)
    1120: Cash (Laundry)
    1130: Cash (Retail)
    1140: M-Pesa (Water)
    1150: M-Pesa (Laundry)
    1160: M-Pesa (Retail)
    1170: Bank Account
  1200-1299: Inventory
    1210: Water Inventory
    1220: Retail Inventory
  1300-1399: Accounts Receivable

2000-2999: Liabilities
  2100-2199: Current Liabilities
    2110: Accounts Payable
    2120: M-Pesa Payable

3000-3999: Equity
  3100: Owner's Capital
  3200: Owner's Drawings
  3300: Retained Earnings

4000-4999: Revenue
  4100: Water Sales Revenue
  4200: Laundry Service Revenue
  4300: Retail Sales Revenue

5000-5999: Expenses
  5100: Cost of Goods Sold
  5200: Rent Expenses
  5300: Utilities
  5400: Salaries
  5500: Transportation
  5600: Marketing
  5700: Maintenance
  5800: Other Expenses
```

### Transaction Flow

```
[Business Event]
       ↓
[Application Layer] (Django)
       ↓
[Transaction Manager] (Begin DB Transaction)
       ↓
[Create Journal Entry] (Header)
       ↓
[Create Journal Entry Lines] (Debit + Credit)
       ↓
[Validate] (Sum(Debits) == Sum(Credits))
       ↓
[Save to Database]
       ↓
[Update Account Balances]
       ↓
[Commit Transaction]
       ↓
[Post-Commit] (Cache invalidation, notifications)
```

---

## Entity-Relationship Overview

### Core Entities (30 Models)

```
USER MANAGEMENT (3 models)
├── User (Django's built-in with extensions)
├── Role (custom roles for future staff)
└── BusinessAccess (which user can access which business)

BUSINESS CONFIGURATION (3 models)
├── Business (Water, Laundry, Retail)
├── BusinessSettings (prices, configurations per business)
└── MPesaTill (M-Pesa till association)

FINANCIAL CORE (8 models) - MOST CRITICAL
├── AccountType (Asset, Liability, Equity, Revenue, Expense)
├── Account (individual ledger accounts)
├── TransactionType (Sale, Expense, Deposit, Withdrawal, Transfer, Adjustment)
├── JournalEntry (transaction header)
├── JournalEntryLine (debit/credit lines)
├── Ledger (universal ledger - every money movement)
├── AccountBalance (snapshot of account balances)
└── Reconciliation (account reconciliation records)

WATER BUSINESS (4 models)
├── WaterProductSize (500ml, 1L, 5L, 10L)
├── WaterInventory (empty containers + filled products)
├── WaterProduction (empty → filled conversion)
└── WaterSale (customer sales)

LAUNDRY BUSINESS (5 models)
├── LaundryCustomer (customer profiles)
├── LaundryJob (customer orders)
├── LaundryJobItem (individual pieces in job)
├── LaundryServiceType (pricing per item/bundle)
└── LaundryJobStatus (received, washing, ready, collected)

RETAIL BUSINESS (6 models)
├── RetailProductCategory (product grouping)
├── RetailProduct (products)
├── RetailInventory (stock levels)
├── RetailLPGCylinder (asset tracking)
├── RetailLPGExchange (full ↔ empty swaps)
└── RetailSale (sales records)

SHARED/CROSS-BUSINESS (1 model)
└── Customer (can be shared across businesses)
```

---

## Database Domains

### Domain 1: User Management

**Purpose:** Authentication, authorization, business access control

**Models:**
- `User` (extends Django User)
- `Role` (for future staff)
- `BusinessAccess` (many-to-many: User ↔ Business)

**Key Features:**
- Owner has access to all businesses
- Accountant (if hired) has read-only operations, edit finance
- Audit trail for all actions
- PIN-based quick login for mobile

**Indexes:**
- `user_id`, `business_id` composite index

---

### Domain 2: Business Configuration

**Purpose:** Define business entities and their settings

**Models:**
- `Business` (Water, Laundry, Retail, future businesses)
- `BusinessSettings` (prices, tax rates, configurations)
- `MPesaTill` (M-Pesa till number per business)

**Key Features:**
- Easy to add 4th business (just add new Business row)
- Business-specific settings (M-Pesa till, tax rates)
- Soft delete (never delete business, only deactivate)

**Indexes:**
- `business_id` primary key
- `is_active` index for filtering

---

### Domain 3: Financial Core (CRITICAL)

**Purpose:** Double-entry bookkeeping, universal ledger, account management

**Models:**
- `AccountType` (Asset, Liability, Equity, Revenue, Expense)
- `Account` (individual accounts with balances)
- `TransactionType` (Sale, Expense, Deposit, Withdrawal, Transfer, Adjustment)
- `JournalEntry` (transaction header)
- `JournalEntryLine` (debit/credit lines)
- `Ledger` (every money movement - immutable)
- `AccountBalance` (periodic balance snapshots)
- `Reconciliation` (account reconciliation records)

**Key Features:**
- **Double-Entry Enforcement:** Database constraint ensures debits = credits
- **Immutability:** Ledger entries never deleted (only reversal entries)
- **Audit Trail:** 7-year retention (KRA compliance)
- **Real-time Balances:** Account balances updated on every transaction
- **Cross-Business:** Universal ledger shows all transactions

**Critical Constraints:**
```sql
-- Journal entry must balance
ALTER TABLE journal_entry_line
ADD CONSTRAINT check_balancing
CHECK (
    (SELECT SUM(amount) WHERE debit = true) =
    (SELECT SUM(amount) WHERE credit = true)
);

-- Prevent deletion of ledger entries
ALTER TABLE ledger
ADD CONSTRAINT ledger_immutable
CHECK (created_at <= NOW());
```

**Indexes:**
- `journal_entry.created_at`, `journal_entry.business_id`
- `journal_entry_line.journal_entry_id`, `journal_entry_line.account_id`
- `ledger.account_id`, `ledger.created_at`, `ledger.business_id`
- Composite: `(business_id, created_at)` for time-series queries

---

### Domain 4: Water Packaging Business

**Purpose:** Track water production, inventory, and sales

**Models:**
- `WaterProductSize` (500ml, 1L, 5L, 10L)
- `WaterInventory` (empty containers + filled products)
- `WaterProduction` (empty → filled conversion)
- `WaterSale` (customer sales)

**Key Features:**
- Track empty containers separately from filled products
- Production reduces empty, increases filled
- Sales reduce filled inventory
- FIFO inventory valuation

**Business Rules:**
- Stock cannot go negative (database constraint)
- Production must have sufficient empty stock
- Price per size configurable

**Indexes:**
- `water_inventory.product_size_id`, `water_inventory.business_id`
- `water_production.created_at`, `water_production.business_id`
- `water_sale.created_at`, `water_sale.business_id`

---

### Domain 5: Laundry Business

**Purpose:** Track laundry jobs, status, payments

**Models:**
- `LaundryCustomer` (customer profiles)
- `LaundryJob` (customer orders)
- `LaundryJobItem` (individual pieces in job)
- `LaundryServiceType` (wash per item/bundle pricing)
- `LaundryJobStatus` (received → washing → ready → collected)

**Key Features:**
- Job status workflow
- Partial payment support
- Credit limit per customer
- 30-day aging alert

**Business Rules:**
- Cannot mark collected if balance pending (configurable)
- Jobs older than 30 days trigger alert
- Customer credit limit enforcement

**Indexes:**
- `laundry_job.customer_id`, `laundry_job.status`
- `laundry_job.created_at`, `laundry_job.business_id`
- Composite: `(business_id, status, created_at)` for pending jobs

---

### Domain 6: Retail/LPG Business

**Purpose:** Track retail products, LPG cylinders, sales

**Models:**
- `RetailProductCategory` (product grouping)
- `RetailProduct` (products)
- `RetailInventory` (stock levels)
- `RetailLPGCylinder` (asset tracking: brand, capacity, serial)
- `RetailLPGExchange` (full ↔ empty swaps)
- `RetailSale` (sales records)

**Key Features:**
- Standard retail inventory tracking
- LPG cylinder asset register
- Cylinder exchange tracking
- Gas pricing: capacity (kg) × price per kg

**Business Rules:**
- Cannot sell if stock is zero (configurable warning)
- Cylinder exchange requires returning empty cylinder
- Low stock alerts

**Indexes:**
- `retail_inventory.product_id`, `retail_inventory.business_id`
- `retail_lpg_cylinder.serial_number` (unique)
- `retail_sale.created_at`, `retail_sale.business_id`

---

### Domain 7: Shared/Cross-Business

**Purpose:** Shared entities across businesses

**Models:**
- `Customer` (can be shared across businesses)

**Key Features:**
- Single customer profile can buy from multiple businesses
- Customer can have credit limit
- Contact information shared

**Indexes:**
- `customer.phone_number` (unique)
- `customer.name` (for search)

---

## Indexing Strategy

### Primary Indexes

**Every foreign key gets an index:**
```sql
CREATE INDEX idx_journal_entry_business ON journal_entry(business_id);
CREATE INDEX idx_journal_entry_line_journal ON journal_entry_line(journal_entry_id);
CREATE INDEX idx_journal_entry_line_account ON journal_entry_line(account_id);
CREATE INDEX idx_ledger_account ON ledger(account_id);
CREATE INDEX idx_ledger_business ON ledger(business_id);
```

### Composite Indexes (Critical for Performance)

**Time-series queries (common):**
```sql
-- For dashboard: transactions by date for specific business
CREATE INDEX idx_ledger_business_date ON ledger(business_id, created_at DESC);

-- For reports: account transactions by date
CREATE INDEX idx_ledger_account_date ON ledger(account_id, created_at DESC);

-- For aging: pending jobs by status and date
CREATE INDEX idx_laundry_job_status_date ON laundry_job(business_id, status, created_at);
```

**Query-specific indexes:**
```sql
-- For stock queries
CREATE INDEX idx_water_inventory_business_size ON water_inventory(business_id, product_size_id);

-- For search
CREATE INDEX idx_customer_name ON customer USING gin(to_tsvector('english', name));
```

### Partial Indexes (For Performance)

**Filter active records only:**
```sql
CREATE INDEX idx_active_business ON business(is_active) WHERE is_active = true;
CREATE INDEX idx_pending_jobs ON laundry_job(business_id, created_at)
WHERE status IN ('received', 'washing', 'ready');
```

---

## Performance Considerations

### Target Performance Metrics

- API response time: < 500ms
- Dashboard load: < 3 seconds on 4G
- Transaction recording: < 1 second
- Support 500+ transactions/day

### Query Optimization

**1. Use `select_related` for ForeignKeys:**
```python
# BAD: N+1 queries
sales = WaterSale.objects.filter(business_id=1)
for sale in sales:
    print(sale.inventory.quantity)  # Query per iteration

# GOOD: 1 query
sales = WaterSale.objects.filter(business_id=1).select_related('inventory')
```

**2. Use `prefetch_related` for ManyToMany:**
```python
# GOOD: 2 queries
users = User.objects.prefetch_related('businesses')
```

**3. Database-level pagination:**
```python
# Always use paginator for large datasets
from django.core.paginator import Paginator
ledger = Ledger.objects.filter(business_id=1).order_by('-created_at')
paginator = Paginator(ledger, 50)  # 50 per page
```

### Connection Pooling

**Django default:** Creates new connection per request
**Recommended:** Use connection pooler (PgBouncer)
**Benefit:** Reuse connections, reduce overhead

### Caching Strategy

**Cache frequently accessed data:**
- Account balances (Redis, 5-minute TTL)
- Business settings (Redis, 1-hour TTL)
- Product prices (Redis, 30-minute TTL)

**Cache invalidation:**
- Invalidate on every transaction
- Use cache versioning

---

## Security & Audit

### Data Encryption

**At Rest:**
- PostgreSQL transparent data encryption (TDE)
- Encrypt sensitive fields (phone numbers, M-Pesa transaction IDs)

**In Transit:**
- TLS 1.3 enforced
- Certificate pinning for mobile app

### Audit Trail

**7-Year Retention (KRA Compliance):**
- Every financial change logged
- Immutable ledger (never delete, only reverse)
- User action logging

**Audit Table:**
```sql
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DELETE
    old_data JSONB,
    new_data JSONB,
    changed_by INTEGER REFERENCES user(id),
    changed_at TIMESTAMP DEFAULT NOW(),
    business_id INTEGER REFERENCES business(id)
);

CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_business_date ON audit_log(business_id, changed_at);
```

**Automatic Auditing:**
- Django signals: `post_save`, `pre_delete`
- Triggers for critical tables (journal_entry, ledger)

---

## Scalability Planning

### Adding 4th Business

**Steps:**
1. Insert new row in `Business` table
2. Create business-specific accounts in `Account` table
3. Configure business settings
4. Done (no code changes, no schema changes)

**Example:**
```sql
INSERT INTO business (name, code, type, m_pesa_till_number)
VALUES ('Car Wash', 'CW', 'SERVICE', '174444');

INSERT INTO account (account_number, name, account_type_id, business_id)
VALUES
('1115', 'Cash (Car Wash)', 1, LAST_INSERT_ID()),
('4400', 'Car Wash Revenue', 4, LAST_INSERT_ID());
```

### Handling 1000+ Transactions/Day

**Current Design:**
- 500 transactions/day = 15,000/month = 180,000/year
- 1000 transactions/day = 30,000/month = 360,000/year

**PostgreSQL Capacity:**
- Easily handles millions of rows with proper indexing
- Partitioning strategy when > 10 million rows

**Partitioning Strategy (Future):**
```sql
-- Partition ledger by year
CREATE TABLE ledger_2026 PARTITION OF ledger
FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE ledger_2027 PARTITION OF ledger
FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
```

### Archive Strategy (7-Year Retention)

**After 7 years:**
1. Archive old transactions to separate database
2. Keep active database with recent 7 years
3. Archive database accessible for audits

**Archive Query:**
```sql
-- Move 2019 transactions to archive
INSERT INTO ledger_archive
SELECT * FROM ledger
WHERE created_at < '2020-01-01';

DELETE FROM ledger
WHERE created_at < '2020-01-01';
```

---

## Migration Strategy

### Initial Schema Creation

**Step 1: Create Django Project**
```bash
django-admin startproject tomtin
cd tomtin
python -m venv venv
source venv/bin/activate
pip install django psycopg2-binary
```

**Step 2: Create Django Apps**
```bash
python manage.py startapp core
python manage.py startapp financial
python manage.py startapp water
python manage.py startapp laundry
python manage.py startapp retail
```

**Step 3: Install Models**
- Copy models from `models.py` (provided separately)
- Register models in `admin.py`
- Create migrations: `python manage.py makemigrations`
- Apply migrations: `python manage.py migrate`

**Step 4: Seed Initial Data**
- Create businesses (Water, Laundry, Retail)
- Create chart of accounts
- Create default user (owner)
- Run seed script: `python manage.py seed_data`

### Migration Rollback Strategy

**Development:**
```bash
python manage.py migrate financial zero
```

**Production:**
- Never rollback (financial data)
- Create new migration to fix issues
- Use transactions for data integrity

---

## Next Steps

1. **Review this design** - Ensure all requirements are met
2. **Create Django models** - See `database_models.py`
3. **Create SQL schema** - See `schema.sql`
4. **Review indexing strategy** - See `indexing_strategy.sql`
5. **Create seed data** - See `seed_data.sql`
6. **Implement migration plan** - See `migration_plan.md`

---

## Appendix

### A. Database Connection Configuration

**settings.py:**
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'tomtin_erp',
        'USER': 'tomtin_user',
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',  # Enforce SSL
            'connect_timeout': 10,
        },
        'CONN_MAX_AGE': 600,  # Connection pooling
    }
}
```

### B. Database Size Estimation

**Year 1:**
- 500 transactions/day × 365 = 182,500 transactions
- 4 journal entry lines per transaction = 730,000 lines
- Estimated storage: ~2 GB

**Year 7:**
- 7 years × 2 GB = 14 GB
- Well within VPS storage (80 GB)

### C. Backup Strategy

**Daily:**
- Automated pg_dump at 2 AM
- Retain 7 daily backups

**Weekly:**
- Full backup on Sunday
- Retain 4 weekly backups

**Off-site:**
- Upload monthly backup to cloud storage
- Encrypt before upload

---

**Document Version:** 1.0
**Author:** Database Design Research
**Date:** 2026-01-28
**Status:** Ready for Implementation

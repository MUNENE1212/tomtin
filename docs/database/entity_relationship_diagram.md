# Entity-Relationship Diagram - Multi-Business ERP System

**Last Updated:** 2026-01-28
**Total Models:** 32
**Database:** PostgreSQL 15+

---

## Overview

This document describes the Entity-Relationship (ER) Diagram for the multi-business ERP system. The system is organized into 7 domains with clear relationships between entities.

**Legend:**
- `1:1` = One-to-One relationship
- `1:N` = One-to-Many relationship
- `N:M` = Many-to-Many relationship
- `(FK)` = Foreign Key
- `(PK)` = Primary Key
- `✓` = Required field
- `○` = Optional field

---

## Domain 1: User Management (3 Models)

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER MANAGEMENT                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │    User      │         │     Role     │                     │
│  ├──────────────┤         ├──────────────┤                     │
│  │ id (PK)      │         │ id (PK)      │                     │
│  │ email ✓      │         │ name ✓       │                     │
│  │ phone ✓     M:N────────│ permissions  │                     │
│  │ is_owner    ─┼─────────│ is_active    │                     │
│  │ is_acctant   │         │              │                     │
│  └──────────────┘         └──────────────┘                     │
│         │                                                        │
│         │                                                     N:M │
│         └───────────────────────────────────┐                   │
│                                            ▼                   │
│                                  ┌──────────────┐               │
│                                  │BusinessAccess│               │
│                                  ├──────────────┤               │
│                                  │ user_id (FK) │               │
│                                  │ business_id  │               │
│                                  │ permission   │               │
│                                  └──────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

**Relationships:**
- User ↔ Role: Many-to-Many (future use)
- User ↔ Business: Many-to-Many through BusinessAccess
- BusinessAccess: Junction table with permission level

---

## Domain 2: Business Configuration (3 Models)

```
┌─────────────────────────────────────────────────────────────────┐
│                      BUSINESS CONFIGURATION                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         1:1         ┌──────────────────────┐ │
│  │   Business   │◄────────────────────┤  BusinessSettings    │ │
│  ├──────────────┤                     ├──────────────────────┤ │
│  │ id (PK)      │                     │ business_id (FK)     │ │
│  │ name ✓       │                     │ tax_rate             │ │
│  │ code ✓       │                     │ currency_code        │ │
│  │ business_type│                     │ low_stock_threshold  │ │
│  │ m_pesa_till  │                     └──────────────────────┘ │
│  └──────────────┘                                             │
│         │                                                      │
│         │ 1:N                                                 │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │  MPesaTill   │                                             │
│  ├──────────────┤                                             │
│  │ id (PK)      │                                             │
│  │ business_id  │                                             │
│  │ till_number  │                                             │
│  │ consumer_key │                                             │
│  └──────────────┘                                             │
└─────────────────────────────────────────────────────────────────┘
```

**Relationships:**
- Business ↔ BusinessSettings: One-to-One
- Business ↔ MPesaTill: One-to-Many (each business can have multiple tills)

---

## Domain 3: Financial Core (8 Models) - CRITICAL

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FINANCIAL CORE (CRITICAL)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐         1:N         ┌──────────────┐                     │
│  │ AccountType  │────────────────────│   Account    │                     │
│  ├──────────────┤                     ├──────────────┤                     │
│  │ id (PK)      │                     │ id (PK)      │                     │
│  │ name ✓       │                     │ account_no   │                     │
│  │ code ✓       │                     │ name ✓       │                     │
│  │ type ✓       │         1:N────────│ account_type │◄────┐               │
│  │ normal_bal   │────────┘           │ business_id  │     │               │
│  └──────────────┘                     │ current_bal  │     │               │
│                                       └──────────────┘     │               │
│                                             │              │               │
│                                             │ 1:N          │               │
│                                             ▼              │               │
│  ┌──────────────────┐              ┌──────────────┐       │               │
│  │ TransactionType  │              │JournalEntry  │       │               │
│  ├──────────────────┤              ├──────────────┤       │               │
│  │ id (PK)          │◄─────────────│ id (PK)      │       │               │
│  │ name ✓           │     1:N      │ entry_number│       │               │
│  │ code ✓           │              │ business_id  │───────┘               │
│  └──────────────────┘              │ trans_date   │ 1:N                   │
│                                   │ total_debit  │────────┐               │
│                                   │ total_credit │        │               │
│                                   │ created_by   │        │               │
│                                   └──────────────┘        │               │
│                                          │ 1:N            │               │
│                                          ▼                │               │
│                                   ┌──────────────┐        │               │
│                                   │JournalEntry  │        │               │
│                                   │    Line      │        │               │
│                                   ├──────────────┤        │               │
│                                   │ je_id (FK)   │        │               │
│                                   │ account_id   │────────┘               │
│                                   │ is_debit     │                        │
│                                   │ amount       │                        │
│                                   └──────────────┘                        │
│                                          │                                │
│                                          │ 1:N                            │
│                                          ▼                                │
│                                   ┌──────────────┐                        │
│                                   │   Ledger     │                        │
│                                   ├──────────────┤                        │
│                                   │ id (PK)      │                        │
│                                   │ je_id (FK)   │                        │
│                                   │ jel_id (FK)  │                        │
│                                   │ account_id   │                        │
│                                   │ business_id  │                        │
│                                   │ trans_date   │                        │
│                                   │ is_debit     │                        │
│                                   │ amount       │                        │
│                                   │ bal_after    │                        │
│                                   └──────────────┘                        │
│                                          │                                │
│                                          │ 1:N                            │
│                                          ▼                                │
│                                   ┌──────────────┐                        │
│                                   │AccountBalance│                        │
│                                   ├──────────────┤                        │
│                                   │ account_id   │                        │
│                                   │ business_id  │                        │
│                                   │ balance_date │                        │
│                                   │ closing_bal  │                        │
│                                   └──────────────┘                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Critical Relationships:**

1. **Account Hierarchy:**
   - AccountType (1) → Account (N)
   - Account (1) → Account (N) (parent-child for sub-accounts)

2. **Journal Entry Flow:**
   - JournalEntry (1) → JournalEntryLine (N)
   - JournalEntry must balance: SUM(debits) = SUM(credits)
   - JournalEntryLine (1) → Ledger (N)

3. **Ledger Immutability:**
   - Ledger entries cannot be deleted or modified
   - Only reversal entries can correct errors
   - Every financial transaction creates ledger entries

4. **Account Balance Snapshots:**
   - AccountBalance stores periodic snapshots
   - Improves query performance (vs. calculating from all ledger entries)

---

## Domain 4: Water Packaging Business (4 Models)

```
┌─────────────────────────────────────────────────────────────────┐
│                      WATER PACKAGING BUSINESS                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐         1:N         ┌──────────────────┐  │
│  │WaterProductSize  │────────────────────│ WaterInventory   │  │
│  ├──────────────────┤                     ├──────────────────┤  │
│  │ id (PK)          │                     │ id (PK)          │  │
│  │ name ✓           │                     │ business_id (FK) │  │
│  │ volume_ml        │                     │ product_size_id  │  │
│  │ default_price    │                     │ type (empty/fill)│  │
│  └──────────────────┘                     │ quantity         │  │
│                                           │ selling_price    │  │
│                                           └──────────────────┘  │
│         │                                   │                   │
│         │ 1:N                               │ 1:N               │
│         ▼                                   ▼                   │
│  ┌──────────────────┐             ┌──────────────────┐         │
│  │ WaterProduction  │             │   WaterSale      │         │
│  ├──────────────────┤             ├──────────────────┤         │
│  │ id (PK)          │             │ id (PK)          │         │
│  │ business_id (FK) │             │ business_id (FK) │         │
│  │ product_size_id  │             │ customer_id (FK) │◄─────┐   │
│  │ qty_produced     │             │ product_size_id  │      │   │
│  │ production_cost  │             │ qty_sold         │      │   │
│  │ prod_date        │             │ total_amount     │      │   │
│  └──────────────────┘             │ payment_method   │      │   │
│                                   │ sale_date        │      │   │
│                                   │ journal_entry_id ├──────┼───┤
│                                   └──────────────────┘      │   │
│                                                             │   │
│  ┌──────────────────┐                                     │   │
│  │    Customer      │─────────────────────────────────────┘   │
│  ├──────────────────┤                                         │
│  │ id (PK)          │                                         │
│  │ name ✓          │                                         │
│  │ phone ✓         │                                         │
│  └──────────────────┘                                         │
└─────────────────────────────────────────────────────────────────┘
```

**Business Rules:**

1. **Inventory Tracking:**
   - Empty containers tracked separately from filled products
   - Production reduces empty quantity, increases filled quantity
   - Sales reduce filled quantity only

2. **Financial Integration:**
   - WaterSale → JournalEntry (automatic double-entry)
   - Debit: Cash/M-Pesa account
   - Credit: Water Sales Revenue account

3. **Stock Validation:**
   - Cannot sell if stock = 0 (unless allow_negative_stock = TRUE)
   - Cannot produce if insufficient empty stock

---

## Domain 5: Laundry Business (5 Models)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         LAUNDRY BUSINESS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐         1:1          ┌──────────────────────┐     │
│  │  Customer    │─────────────────────│LaundryCustomer       │     │
│  ├──────────────┤                     ├──────────────────────┤     │
│  │ id (PK)      │                     │ id (PK)              │     │
│  │ name ✓       │                     │ customer_id (FK)     │     │
│  │ phone ✓      │                     │ customer_code        │     │
│  └──────────────┘                     │ credit_limit         │     │
│         │                             │ current_balance      │     │
│         │ 1:N                         └──────────────────────┘     │
│         ▼                                    │                      │
│  ┌──────────────────┐                      │ 1:N                 │
│  │LaundryServiceType│                      │                     │
│  ├──────────────────┤                      ▼                     │
│  │ id (PK)          │             ┌──────────────────────┐       │
│  │ name ✓           │             │   LaundryJob         │       │
│  │ pricing_type     │             ├──────────────────────┤       │
│  │ default_price    │             │ id (PK)              │       │
│  └──────────────────┘             │ business_id (FK)     │       │
│         │                         │ customer_id (FK)     │       │
│         │ 1:N                     │ job_number           │       │
│         │                         │ status               │       │
│         │                         │ received_date        │       │
│         ▼                         │ total_amount         │       │
│  ┌──────────────────┐             │ amount_paid          │       │
│  │  LaundryJobItem  │◄────────────│ balance_due          │       │
│  ├──────────────────┤     1:N     │ journal_entry_id (FK)├───┐   │
│  │ id (PK)          │             └──────────────────────┘   │   │
│  │ job_id (FK)      │                                      │   │
│  │ service_type (FK)│◄─────────────────────────────────────┘   │
│  │ quantity         │                                          │
│  │ unit_price       │                                          │
│  │ line_total       │                                          │
│  └──────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

**Business Rules:**

1. **Job Status Workflow:**
   - received → washing → drying → ready → collected
   - Status transitions enforced by application

2. **Payment Tracking:**
   - Jobs can have partial payments
   - Balance tracked in LaundryCustomer.current_balance
   - Cannot mark collected if balance_due > 0 (configurable)

3. **Financial Integration:**
   - LaundryJob → JournalEntry (automatic)
   - Debit: Cash/M-Pesa/Accounts Receivable
   - Credit: Laundry Service Revenue

4. **Aging Alert:**
   - Jobs older than 30 days trigger alert
   - Checked via background job

---

## Domain 6: Retail/LPG Business (7 Models)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RETAIL/LPG BUSINESS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────┐          1:N          ┌──────────────────────┐   │
│  │RetailProductCategory │───────────────────────│   RetailProduct      │   │
│  ├──────────────────────┤                      ├──────────────────────┤   │
│  │ id (PK)              │                      │ id (PK)              │   │
│  │ name ✓               │                      │ product_code ✓       │   │
│  │ parent_category_id   │                      │ name ✓               │   │
│  └──────────────────────┘                      │ category_id (FK)     │   │
│         │                                      │ is_lpg               │   │
│         │                                      └──────────────────────┘   │
│         │                                           │                     │
│         │ 1:N                                       │ 1:N                 │
│         ▼                                           ▼                     │
│  ┌──────────────────────┐               ┌──────────────────────┐         │
│  │  RetailInventory     │               │    RetailSale        │         │
│  ├──────────────────────┤               ├──────────────────────┤         │
│  │ id (PK)              │               │ id (PK)              │         │
│  │ business_id (FK)     │               │ business_id (FK)     │         │
│  │ product_id (FK)      │               │ customer_id (FK)     │◄─────┐   │
│  │ quantity_in_stock    │               │ sale_number          │      │   │
│  │ selling_price        │               │ total_amount         │      │   │
│  │ reorder_level        │               │ payment_method       │      │   │
│  └──────────────────────┘               │ journal_entry_id (FK)├──┐   │   │
│         │                               └──────────────────────┘  │   │   │
│         │                                    │ 1:N                │   │   │
│         ▼                                    ▼                    │   │   │
│  ┌──────────────────────┐          ┌──────────────────────┐      │   │   │
│  │ RetailLPGCylinder    │          │  RetailSaleItem      │      │   │   │
│  ├──────────────────────┤          ├──────────────────────┤      │   │   │
│  │ id (PK)              │          │ id (PK)              │      │   │   │
│  │ business_id (FK)     │          │ sale_id (FK)         │      │   │   │
│  │ brand ✓              │          │ product_id (FK)      │      │   │   │
│  │ capacity_kg          │◄─────────│ quantity             │      │   │   │
│  │ serial_number ✓      │          │ unit_price           │      │   │   │
│  │ status               │          │ line_total           │      │   │   │
│  └──────────────────────┘          └──────────────────────┘      │   │   │
│         │                                                          │   │   │
│         │ 1:N                                                      │   │   │
│         ▼                                                          │   │   │
│  ┌──────────────────────┐                                        │   │   │
│  │ RetailLPGExchange    │                                         │   │   │
│  ├──────────────────────┤                                         │   │   │
│  │ id (PK)              │                                         │   │   │
│  │ business_id (FK)     │                                         │   │   │
│  │ full_cylinder_id (FK)│                                         │   │   │
│  │ empty_cylinder_id(FK)│                                         │   │   │
│  │ capacity_kg          │                                         │   │   │
│  │ total_amount         │                                         │   │   │
│  │ journal_entry_id (FK)├─────────────────────────────────────────┘   │   │
│  └──────────────────────┘                                             │   │
│  ┌──────────────────┐                                                 │   │
│  │    Customer      │─────────────────────────────────────────────────┘   │
│  ├──────────────────┤                                                     │
│  │ id (PK)          │                                                     │
│  │ name ✓          │                                                     │
│  │ phone ✓         │                                                     │
│  └──────────────────┘                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Business Rules:**

1. **Inventory Management:**
   - RetailInventory tracks stock levels per business
   - Low stock alert when quantity_in_stock <= reorder_level
   - Cannot sell if stock = 0 (configurable)

2. **LPG Cylinder Tracking:**
   - Each cylinder has unique serial_number
   - Status: full, empty, customer, maintenance
   - Exchange requires returning empty cylinder (optional)

3. **Financial Integration:**
   - RetailSale → JournalEntry (automatic)
   - RetailLPGExchange → JournalEntry (automatic)
   - Debit: Cash/M-Pesa/Bank
   - Credit: Retail Sales Revenue / LPG Sales Revenue

4. **Sale Items:**
   - RetailSale (header) → RetailSaleItem (line items)
   - Supports multiple products per sale
   - Automatic inventory deduction

---

## Domain 7: Shared/Cross-Business (1 Model)

```
┌─────────────────────────────────────────────────────────────────┐
│                      SHARED/CROSS-BUSINESS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                               │
│  │  Customer    │◄────────┐                                     │
│  ├──────────────┤         │                                     │
│  │ id (PK)      │         │                                     │
│  │ name ✓       │         │                                     │
│  │ phone ✓      │         │                                     │
│  │ email        │         │                                     │
│  │ customer_type│         │                                     │
│  └──────────────┘         │                                     │
│         │                 │                                     │
│         │ 1:N             │                                     │
│         ├─────────────────┼──────────────────┐                 │
│         ▼                 ▼                  ▼                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐           │
│  │ WaterSale    │ │ LaundryJob   │ │ RetailSale   │           │
│  │ (water biz)  │ │ (laundry biz)│ │ (retail biz) │           │
│  └──────────────┘ └──────────────┘ └──────────────┘           │
│                                                                 │
│  Note: Customer is shared across all businesses                │
│        Same customer can buy from multiple businesses           │
└─────────────────────────────────────────────────────────────────┘
```

**Design Decision:**

- Customer table is **shared** across all businesses
- Benefits:
  - Single customer profile
  - Unified customer view
  - Cross-business purchase history
  - Simpler data management

---

## Cross-Domain Relationships

### Financial Integration (Most Critical)

```
                    ┌──────────────────┐
                    │  JournalEntry    │
                    │  (Financial)     │
                    └────────┬─────────┘
                             │ 1:1
                             ▼
        ┌────────────────────┴────────────────────┐
        │                                          │
        ▼                                          ▼
┌──────────────┐                          ┌──────────────┐
│  WaterSale   │                          │ LaundryJob   │
└──────────────┘                          └──────────────┘
        │                                          │
        └──────────────────┬───────────────────────┘
                           │
                           ▼
                  ┌──────────────┐
                  │  RetailSale  │
                  └──────────────┘
                           │
                           ▼
                  ┌──────────────┐
                  │ RetailLPG    │
                  │  Exchange    │
                  └──────────────┘
```

**Rule:** Every sale/service creates a JournalEntry
- WaterSale → JournalEntry (automatic)
- LaundryJob → JournalEntry (on payment)
- RetailSale → JournalEntry (automatic)
- RetailLPGExchange → JournalEntry (automatic)

### Business Isolation

```
┌──────────────────────────────────────────────────────────────┐
│                        Business                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ All operational data filtered by business_id:        │    │
│  │ - WaterInventory (business_id)                       │    │
│  │ - LaundryJob (business_id)                           │    │
│  │ - RetailInventory (business_id)                      │    │
│  │ - WaterSale (business_id)                            │    │
│  │                                                      │    │
│  │ Shared data (no business_id):                        │    │
│  │ - Customer (can be shared)                           │    │
│  │ - Chart of Accounts (some shared, some business-specific)│
│  │ - Ledger (has business_id, but unified view)        │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### Sale Recording Flow (Water Business)

```
┌─────────┐    ┌──────────┐    ┌──────────────┐    ┌──────────┐
│  User   │───▶│ WaterSale│───▶│ JournalEntry │───▶│  Ledger  │
│ Records │    │ Created  │    │  (Auto)      │    │ (Immutable)│
│ Sale    │    │          │    │              │    │          │
└─────────┘    └──────────┘    └──────────────┘    └──────────┘
                    │                                    │
                    ▼                                    ▼
             ┌──────────────┐                    ┌──────────┐
             │ Water        │                    │ Account  │
             │ Inventory    │                    │ Balances │
             │ (Reduced)    │                    │ (Updated)│
             └──────────────┘                    └──────────┘
```

### Laundry Job Flow

```
┌─────────┐    ┌──────────┐    ┌──────────────┐
│  User   │───▶│LaundryJob│───▶│ LaundryJob   │
│ Creates │    │ Created  │    │   Items      │
│  Job    │    │          │    │  (Line items)│
└─────────┘    └──────────┘    └──────────────┘
                   │
       ┌───────────┼───────────┐
       ▼           ▼           ▼
  ┌────────┐ ┌────────┐ ┌──────────────┐
 │Received │ │Washing │ │    Ready     │
 │ Status │ │ Status │ │   Status     │
 └────────┘ └────────┘ └──────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │  Payment     │
                       │  Recorded    │
                       └──────────────┘
                              │
                              ▼
                       ┌──────────────┐    ┌──────────┐
                       │ JournalEntry │───▶│  Ledger  │
                       │  (Auto)      │    │          │
                       └──────────────┘    └──────────┘
```

---

## Summary Statistics

**Total Models:** 32

**By Domain:**
- User Management: 3 models
- Business Configuration: 3 models
- Financial Core: 8 models
- Water Business: 4 models
- Laundry Business: 5 models
- Retail/LPG Business: 7 models
- Shared/Cross-Business: 1 model
- Audit Logging: 1 model

**Relationships:**
- One-to-One: 3
- One-to-Many: 50+
- Many-to-Many: 2

**Critical Paths:**
1. **Financial Integrity:** JournalEntry → JournalEntryLine → Ledger
2. **Business Isolation:** All operational tables have business_id
3. **Audit Trail:** All changes → AuditLog

---

## Implementation Notes

### Multi-Tenancy Implementation

**Pattern:** Row-level security via `business_id` foreign key

**Query Filter:**
```python
# Automatically filter by business_id
class BusinessAwareManager(models.Manager):
    def get_queryset(self):
        from django.utils.functional import cached_property

        # Get business_id from request context
        business_id = Business.get_current_business_id()

        if business_id:
            return super().get_queryset().filter(business_id=business_id)
        return super().get_queryset()
```

### Double-Entry Enforcement

**Application Level:**
```python
class JournalEntry(models.Model):
    def clean(self):
        total_debit = self.lines.filter(is_debit=True).aggregate(Sum('amount'))
        total_credit = self.lines.filter(is_debit=False).aggregate(Sum('amount'))

        if total_debit != total_credit:
            raise ValidationError("Journal entry must balance")
```

**Database Level:**
```sql
ALTER TABLE journal_entry_line
ADD CONSTRAINT check_balancing
CHECK ((SELECT SUM(amount) WHERE is_debit = true) =
       (SELECT SUM(amount) WHERE is_debit = false));
```

---

## Next Steps

1. **Create Visual ER Diagram** using draw.io, Lucidchart, or dbdiagram.io
2. **Generate Django Models** from this ER diagram (already provided)
3. **Create Migrations** from models
4. **Test Relationships** with sample data
5. **Validate Double-Entry** logic
6. **Performance Test** with realistic data volume

---

**Document Version:** 1.0
**Last Updated:** 2026-01-28
**Status:** Complete

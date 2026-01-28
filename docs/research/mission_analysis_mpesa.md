# M-Pesa Integration Mission Analysis

**Project:** Unified Business Management System (ERP)
**Research Topic:** M-Pesa Daraja API Integration for Django 5.0+
**Date:** 2026-01-28
**Researcher:** Research Agent

---

## 1. CORE GOAL

Integrate Safaricom M-Pesa Daraja API into a Django 5.0+ ERP system to enable:
- STK Push payments (customer initiates via USSD prompt)
- C2B payments (customer pays to till number)
- Automatic payment reconciliation with double-entry ledger
- Support for multiple M-Pesa tills (one per business: Water, Laundry, Retail)
- Zero payment loss tolerance

---

## 2. MISSION REQUIREMENTS (Must Have)

### Financial Integrity Requirements
- **Zero payment loss tolerance** - CRITICAL
  - Every M-Pesa payment must be captured
  - Database transactions mandatory for payment processing
  - Atomic writes to ledger (all-or-nothing)
  - Callback reliability: Must handle missing/delayed callbacks

- **Duplicate detection** - CRITICAL
  - Prevent double-payment accounting
  - Idempotency key generation per transaction
  - Database unique constraints on M-Pesa receipt (M-Pesa transaction ID)
  - Callback replay prevention

- **Payment reconciliation** - CRITICAL
  - Auto-create ledger entries on successful payment
  - Match payments to sales/invoices
  - Handle partial payments
  - Daily till balance reconciliation

### Business Requirements
- **Multiple M-Pesa Tills** - LOCKED (DEC-006)
  - Water Business till (short code)
  - Laundry Business till (short code)
  - Retail/LPG Business till (short code)
  - Each till independent with own credentials

- **Transaction Types**
  - Sales payments (Water sales, Laundry payments, Retail sales)
  - Bill payments (Laundry bills)
  - Deposits (Customer pre-payments, Wallet top-ups)
  - Refunds (reversals)

### Technical Requirements
- **Django 5.0+** - LOCKED (DEC-002)
- **PostgreSQL** - LOCKED (DEC-002)
- **Django REST Framework** - Required for API endpoints
- **Background task queue** - For async callback processing (Django-RQ recommended - DEC-P04)
- **Cache** - For OAuth token storage (Redis - Caching strategy decision)
- **Mobile-first** - Primary user on mobile phone (DEC-004)

---

## 3. CONSTRAINTS (Cannot Violate)

### Budget Constraints
- **Monthly operational cost: $200/month maximum** - LOCKED (DEC-007)
  - M-Pesa API costs: Transaction fees apply per payment
  - No additional API costs for Daraja API (free to integrate)
  - Must fit within VPS hosting budget

### Timeline Constraints
- **MVP: 3 months** - LOCKED (DEC-007)
  - M-Pesa integration in Sprint 3-4 (Weeks 5-8)
  - Must test in sandbox before production
  - Go-live certification with Safaricom required

### Technology Constraints
- **Django 5.0+ only** - LOCKED (DEC-002)
- **PostgreSQL database** - LOCKED (DEC-002)
- **VPS deployment (4GB RAM)** - LOCKED (DEC-002)
  - OAuth token storage must be efficient
  - Callback processing must not consume excessive memory

### Security Constraints
- **Financial data protection**
  - HTTPS enforced (TLS 1.3)
  - API credentials encrypted at rest
  - Callback signature validation
  - Audit trail for all payment actions
  - Rate limiting to prevent abuse

---

## 4. CRITICAL SUCCESS FACTORS

### Reliability (Zero Payment Loss)
1. **Callback Handling**
   - Idempotent callback processing (retry-safe)
   - Fallback: Transaction status query if callback fails
   - Failed callback queue for manual investigation
   - Daily reconciliation report

2. **Error Handling**
   - All M-Pesa error codes handled
   - Failed payments logged with full context
   - Timeout handling (STK Push expires)
   - Insufficient funds handling
   - Network failure retry logic

3. **Data Integrity**
   - Database transactions for payment updates
   - Atomic ledger entry creation
   - Unique constraint on M-Pesa receipt number
   - Idempotency keys prevent duplicates

### Security (Fraud Prevention)
1. **Callback Security**
   - Validate callback source (Safaricom IPs)
   - Signature verification (if provided)
   - Timestamp validation (prevent replay attacks)
   - Amount verification (match expected amount)
   - Till number verification

2. **API Security**
   - OAuth token refresh (don't use expired tokens)
   - Credentials encrypted in database
   - API key rotation strategy
   - Rate limiting (prevent abuse)

### Performance
- STK Push initiation: < 2 seconds
- Callback processing: < 500ms (async with Django-RQ)
- Payment status query: < 1 second
- Support 100+ payments/day per business

---

## 5. M-PESA INTEGRATION REQUIREMENTS MAPPING

### STK Push (Lipa Na M-Pesa Online)
**Use Case:** Customer pays for goods/services at counter

**Flow:**
1. Owner enters amount and customer phone number in Django PWA
2. Django initiates STK Push via Daraja API
3. Customer receives USSD prompt on phone
4. Customer enters M-Pesa PIN
5. Safaricom sends callback to Django server
6. Django processes callback, creates ledger entry, updates sale record
7. PWA shows payment confirmation to owner

**Technical Requirements:**
- OAuth token (valid for 1 hour, cache in Redis)
- STK Push endpoint: `https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest`
- Timestamp generation (format: `YYYYMMDDHHmmss`)
- Password generation (Base64 of Business Shortcode + Passkey + Timestamp)
- Callback URL (must be publicly accessible, HTTPS)
- Idempotency key (prevent duplicate STK Push requests)

**Data Required:**
- Business Short Code (till number)
- Lipa Na M-Pesa Passkey
- Consumer Key & Secret (from Daraja portal)
- Customer phone number (format: `2547XXXXXXXX`)
- Amount (KES)
- Account Reference (sale ID, invoice ID, etc.)
- Transaction Description

**Error Handling:**
- `2001`: Invalid credential (OAuth token expired) → Refresh token, retry
- `2002`: Invalid phone number format → Show validation error
- `2003`: Insufficient funds → Show error to customer
- `2004`: Lower amount limit → Show error
- `2005`: Exceeds upper limit → Show error
- `2006`: Request cancelled by user → Show payment cancelled
- `2007`: Invalid request payload → Log error, retry
- `1032`: Request already received (duplicate) → Use idempotency key
- `1037`: Transaction timeout (customer didn't enter PIN) → Show timeout
- `1036`: Transaction pending (callback not received) → Query status after 30 seconds

### C2B (Customer to Business)
**Use Case:** Customer pays directly to till number (owner not at counter)

**Flow:**
1. Customer sends money to till number via M-Pesa menu
2. Safaricom sends validation request to Django server (optional)
3. Django validates customer/business rules
4. Safaricom sends confirmation request to Django server
5. Django processes payment, creates ledger entry
6. Optional: Django sends SMS acknowledgement to customer

**Technical Requirements:**
- C2B Validation URL (endpoint on Django server)
- C2B Confirmation URL (endpoint on Django server)
- Register C2B URLs with Safaricom (via API)
- Validation logic: Check if customer exists, check business rules
- Confirmation logic: Process payment, create ledger entry

**Data Required:**
- Business Short Code (till number)
- Validation URL: `https://yourdomain.com/mpesa/c2b/validation`
- Confirmation URL: `https://yourdomain.com/mpesa/c2b/confirmation`
- Response must be JSON with `"ResultCode": 0` (success)

**Error Handling:**
- Validation failed → Return `ResultCode: 1`, Safaricom rejects transaction
- Confirmation failed → Queue for manual reconciliation
- Missing callback → Query transaction status after 60 seconds

### Transaction Status Query
**Use Case:** Fallback when STK Push callback fails

**Flow:**
1. Django queries M-Pesa transaction status via API
2. Safaricom returns current status
3. Django updates payment record accordingly

**Technical Requirements:**
- Query endpoint: `https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query`
- Business Short Code
- Timestamp & Password (same as STK Push)
- Merchant Request ID (from STK Push response)
- Checkout Request ID (from STK Push response)

---

## 6. DATABASE SCHEMA IMPLICATIONS

### Required Tables

**mpesa_till** (Multiple tills support)
```
- id (UUID, PK)
- business (FK to Business)
- short_code (Char, till number)
- passkey (Encrypted Char)
- consumer_key (Encrypted Char)
- consumer_secret (Encrypted Char)
- environment (Char: sandbox/production)
- is_active (Boolean)
- created_at, updated_at
```

**mpesa_payment** (Payment records)
```
- id (UUID, PK)
- till (FK to mpesa_till)
- transaction_type (Char: stk_push/c2b)
- transaction_id (Char, M-Pesa receipt, UNIQUE)
- merchant_request_id (Char, STK Push ID)
- checkout_request_id (Char, STK Push ID)
- phone_number (Char)
- amount (Decimal)
- account_reference (Char, sale ID, invoice ID, etc.)
- status (Char: pending/completed/failed/timeout)
- result_code (Char, M-Pesa result code)
- result_desc (Text)
- callback_received_at (DateTime)
- created_at (DateTime)
- business (FK to Business)
```

**mpesa_callback_log** (Audit trail)
```
- id (UUID, PK)
- payment (FK to mpesa_payment)
- callback_type (Char: result/confirmation/validation)
- raw_payload (JSON)
- processed (Boolean)
- processing_error (Text, nullable)
- created_at (DateTime)
```

**mpesa_reconciliation** (Daily reconciliation)
```
- id (UUID, PK)
- till (FK to mpesa_till)
- date (Date)
- expected_count (Integer)
- actual_count (Integer)
- expected_amount (Decimal)
- actual_amount (Decimal)
- discrepancy_count (Integer)
- discrepancy_amount (Decimal)
- status (Char: matched/discrepancy/investigating)
- reconciled_by (FK to User)
- reconciled_at (DateTime)
```

---

## 7. IMPLEMENTATION PRIORITY (MVP Phasing)

### Phase 1: MVP (Sprint 3-4, Weeks 5-8)
**Essential Features:**
1. STK Push for sales payments (all 3 businesses)
2. STK Push callback handling with ledger integration
3. Duplicate detection (idempotency keys)
4. Basic error handling (timeouts, insufficient funds)
5. Transaction status query fallback
6. Manual reconciliation report

### Phase 2: Post-MVP
**Advanced Features:**
1. C2B payments (validation + confirmation)
2. Automatic daily reconciliation
3. Payment analytics dashboard
4. SMS notifications to customers
5. Refunds (transaction reversals)
6. M-Pesa transaction fee calculation

---

## 8. TESTING REQUIREMENTS

### Sandbox Testing (Critical)
- Test all STK Push flows (success, failure, timeout)
- Test duplicate detection (send same request twice)
- Test callback failure scenarios (no callback, late callback)
- Test transaction status query fallback
- Test ledger entry creation accuracy
- Test multi-till setup (3 businesses)
- Test concurrent payment processing
- Test error handling (all M-Pesa error codes)

### Production Readiness Checklist
- HTTPS configured with valid SSL certificate
- Callback URLs accessible from internet (not blocked by firewall)
- OAuth token refresh working
- Idempotency keys unique per request
- Database transactions tested (atomic payment + ledger)
- Daily reconciliation process documented
- Failed payment investigation process documented
- API credentials encrypted in database
- Rate limiting configured
- Audit logging enabled
- Backup/restore tested

---

## 9. GO-LIVE CERTIFICATION PROCESS

### Safaricom Requirements (Typical)
1. **Sandbox Testing**
   - Complete all test scenarios
   - Document test results

2. **UAT (User Acceptance Testing)**
   - Safaricom provides test till number
   - Conduct real transactions (small amounts)
   - Verify callbacks work correctly

3. **Production Access Request**
   - Submit application via Daraja portal
   - Provide business registration documents
   - Provide UAT test results
   - Wait for approval (1-2 weeks typical)

4. **Go-Live**
   - Receive production credentials
   - Update API endpoints (sandbox → production)
   - Monitor first 100 transactions closely
   - Daily reconciliation for first week

---

## 10. RISK ASSESSMENT

### High Risk (Must Mitigate)
1. **Callback Failure**
   - Risk: Payment successful but callback not received
   - Impact: Payment lost, ledger mismatch
   - Mitigation: Transaction status query after 30 seconds, daily reconciliation

2. **Duplicate Payment Processing**
   - Risk: Same payment processed twice
   - Impact: Ledger imbalance, overstatement of revenue
   - Mitigation: Unique constraint on M-Pesa receipt ID, idempotency keys

3. **OAuth Token Expiry**
   - Risk: Token expires during payment initiation
   - Impact: Payment initiation fails
   - Mitigation: Cache token with expiry, refresh 5 minutes before expiry

### Medium Risk
1. **Network Timeouts**
   - Risk: STK Push request times out
   - Impact: Poor UX, customer waits
   - Mitigation: Set 30-second timeout, show loading spinner, retry button

2. **M-Pesa API Downtime**
   - Risk: Safaricom API unavailable
   - Impact: Cannot process payments
   - Mitigation: Fallback to manual recording, sync later, API status monitoring

### Low Risk
1. **Fraudulent Callbacks**
   - Risk: Fake callback from attacker
   - Impact: False payment recorded
   - Mitigation: IP whitelist (Safaricom IPs), signature validation

---

## 11. OPERATIONAL CONSIDERATIONS

### Monitoring Required
- Payment success rate (target: >95%)
- Callback failure rate (target: <2%)
- Average STK Push completion time
- Daily reconciliation discrepancies
- API token refresh failures
- Failed payment error codes distribution

### Maintenance Tasks
- Daily: Reconcile till balances (expected vs actual)
- Weekly: Review failed payment report
- Monthly: Rotate API credentials (optional)
- Quarterly: Audit payment ledger for anomalies

### Documentation Required
- M-Pesa integration runbook (troubleshooting guide)
- Reconciliation procedure
- Failed payment investigation procedure
- API credential management procedure
- Emergency rollback procedure (switch to manual recording)

---

## 12. SUCCESS METRICS

### Technical Metrics
- STK Push success rate: >95%
- Callback processing time: <500ms (p95)
- Callback loss rate: <2% (with status query fallback)
- Duplicate payment rate: 0%
- Ledger accuracy: 100% (always balances)

### Business Metrics
- Payment processing time: <30 seconds (end-to-end)
- Customer satisfaction: No payment complaints
- Financial accuracy: Zero payment loss
- Reconciliation time: <10 minutes daily

---

## END OF MISSION ANALYSIS

**Next Step:** Research specific implementation approaches (Python libraries, custom implementation, code examples)

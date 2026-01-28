# ARCHITECTURE DECISIONS

**Project:** Unified Business Management System
**Version:** 0.1.0
**Last Updated:** 2026-01-28
**Status:** Mission Approved, Research Pending

---

## LOCKED DECISIONS

These decisions have been approved by the business owner and CANNOT be changed without explicit human approval.

### 1. Technology Stack

**Backend Framework: Django 5.0+**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Owner has Django developers available, mature ecosystem, excellent for ERP systems
- Locked: YES
- Constraints: Must use latest stable Django 5.x

**Database: PostgreSQL 15+**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: ACID compliance critical for financial transactions, mature, reliable
- Locked: YES
- Constraints: Must use PostgreSQL 15 or higher

**Frontend: Progressive Web App (PWA) - Mobile-First**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Primary user is on mobile phone (90% of operations), works across iOS/Android, offline capability
- Locked: YES
- Constraints: Must be installable on home screen, work offline for critical functions, optimize for 320px-428px width

### 2. Business Model

**Multi-Business Architecture:**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Businesses:
  1. Water Packaging
  2. Laundry
  3. Retail/LPG
- Reasoning: Single owner operating 3 distinct businesses needs unified view with independent operations
- Locked: YES
- Constraints: Each business operates independently, financial core consolidates data

**Primary User: Business Owner on Mobile**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Owner performs all operations (sales, tracking, reporting) primarily from mobile phone
- Locked: YES
- Constraints: All critical functions must work on mobile, < 30 second sale recording, one-handed operation support

### 3. Financial Architecture

**Double-Entry Accounting System**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Legal requirement for audit trail, proper P&L tracking, compliance
- Locked: YES
- Constraints: Universal ledger captures all money movements, ledger must always balance

**M-Pesa Integration (Safaricom Daraja API)**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Primary payment method in Kenya, requires real-time reconciliation
- Locked: YES
- Constraints: Support multiple tills (one per business), handle STK Push and C2B

### 4. Deployment & Infrastructure

**VPS Hosting ($50-100/month budget)**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Cost constraint, need full control, predictable monthly cost
- Locked: YES
- Constraints: Must fit within $200/month total operational budget

**Docker-Based Deployment**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Reasoning: Consistency across environments, easier maintenance
- Locked: YES
- Constraints: Must use Docker containers for all services

### 5. Budget & Timeline

**Total Budget: $15,000 USD**
- Decision Date: 2026-01-28 (from MISSION.md)
- Approved By: Business Owner
- Timeline: MVP in 3 months (by 2026-04-28)
- Locked: YES
- Constraints: Must not exceed budget, phased rollout approach

---

## PENDING DECISIONS (To be determined in Research Stage)

These decisions will be made by the research agent based on technical investigation:

### 1. Frontend Framework
**Options:** React, Vue.js, Svelte
**Research Required:**
- PWA support maturity
- Mobile performance on 3G/4G
- Bundle size impact
- Ecosystem for mobile components
- Offline capability implementation complexity
**Decision Maker:** Research Agent → Human Approval

### 2. Mobile UI Component Library
**Options:** Material-UI, Chakra UI, Tailwind + custom, Vuetify
**Research Required:**
- Touch optimization quality
- Mobile-first design patterns
- Performance on low-end phones
- PWA compatibility
- Bundle size
**Decision Maker:** Research Agent → Human Approval

### 3. Task Queue System
**Options:** Celery + Redis, Django-RQ, BullMQ (if Node), Dramatiq
**Research Required:**
- M-Pesa callback handling
- Background report generation
- Email/SMS queue processing
- Integration complexity with Django
**Decision Maker:** Research Agent → Human Approval

### 4. Caching Strategy
**Options:** Redis, Memcached, Django database cache
**Research Required:**
- Mobile API response optimization
- Session storage for mobile users
- Real-time dashboard caching
- Cost implications
**Decision Maker:** Research Agent → Human Approval

### 5. Offline Data Storage (PWA)
**Options:** IndexedDB, LocalStorage, Dexie.js, PouchDB
**Research Required:**
- Transaction storage for sync
- Storage capacity limits
- Sync conflict resolution strategy
- Mobile browser support
**Decision Maker:** Research Agent → Human Approval

### 6. Chart/Visualization Library
**Options:** Chart.js, Recharts, Victory, ApexCharts
**Research Required:**
- Mobile rendering performance
- Touch interaction support
- Bundle size
- Offline capability
- Chart types needed (line, bar, pie)
**Decision Maker:** Research Agent → Human Approval

### 7. Database ORM Strategy
**Options:** Django ORM (raw), Django-tenant-schemas, Django-multitenant
**Research Required:**
- Multi-business data isolation
- Query performance implications
- Migration complexity
- Development efficiency
**Decision Maker:** Research Agent → Human Approval

### 8. API Authentication
**Options:** JWT, Django REST Framework Token Auth, Session Auth, OAuth2
**Research Required:**
- Mobile app security
- Session timeout handling (2-hour mobile requirement)
- PIN-based quick login feasibility
- Token refresh strategy
**Decision Maker:** Research Agent → Human Approval

### 9. Real-time Updates (if needed)
**Options:** WebSockets (Django Channels), Server-Sent Events, Polling
**Research Required:**
- Multi-user conflict prevention
- Live dashboard updates
- M-Pesa payment notifications
- Mobile battery impact
**Decision Maker:** Research Agent → Human Approval

### 10. Testing Approach
**Options:** Pytest + pytest-django, unittest, nose2
**Research Required:**
- Mobile E2E testing (BrowserStack, local)
- API testing framework
- Financial calculation testing
- 80% coverage requirement
**Decision Maker:** Research Agent → Human Approval

---

## ARCHITECTURAL PRINCIPLES

All decisions MUST adhere to these principles:

### 1. Mobile-First (Critical)
- All UI designed for mobile (320px-428px) first, desktop second
- Touch-optimized (44px minimum touch targets)
- One-handed operation where possible
- Offline-first for critical functions

### 2. Performance
- Page load: < 3 seconds on 4G
- Sale recording: < 30 seconds total
- API response: < 500ms
- PWA bundle: < 5MB

### 3. Data Integrity
- Zero data loss tolerance for financial transactions
- Double-entry accounting enforced
- Database transactions for all financial operations
- Audit trail for every money movement

### 4. Cost-Effectiveness
- Total budget: $15,000
- Monthly operations: < $200
- No unpredictable cloud costs
- Open-source tools preferred

### 5. Simplicity
- Low technical literacy users
- Training time: 1 day per user
- Intuitive interfaces (minimal documentation needed)
- Mobile-optimized UX patterns

---

## INTEGRATION REQUIREMENTS

### M-Pesa (Safaricom Daraja API)
**Status:** Required (MVP)
**Complexity:** High
**Timeline:** Sprint 3-4 (Weeks 5-8)
**Research Needs:**
- STK Push implementation guide
- C2B callback handling best practices
- Duplicate transaction detection
- Sandbox testing approach
- Error handling and retry logic

### Future Integrations (Post-MVP)
- SMS (AfricasTalking)
- WhatsApp Business API
- Receipt printers (thermal)
- Barcode scanners
- KRA tax filing

---

## DEPLOYMENT ARCHITECTURE

### Production Environment
**VPS Specs (to be confirmed in research):**
- RAM: 4GB minimum
- CPU: 2 cores minimum
- Storage: 80GB SSD
- OS: Ubuntu 22.04 LTS

**Docker Containers:**
1. Django (Gunicorn)
2. PostgreSQL
3. Redis (caching + Celery broker)
4. Celery worker
5. Nginx (reverse proxy)

### Environments
1. **Development:** Local (Docker Compose)
2. **Staging:** VPS (for UAT)
3. **Production:** VPS (phased rollout)

---

## SECURITY ARCHITECTURE

### Required (MVP)
- HTTPS enforced (TLS 1.3)
- Data encryption at rest (PostgreSQL)
- Password hashing (bcrypt)
- Rate limiting (login: 5/min)
- CSRF protection
- XSS protection
- SQL injection prevention (ORM only)
- Audit trail for sensitive actions

### Mobile-Specific Security
- Secure token storage (httpOnly cookies)
- 2-hour session timeout
- PIN-based quick login (4-6 digits)
- Biometric authentication support (future)

---

## DOCUMENTATION STATUS

**Completed:**
- MISSION.md ✓
- ARCHITECTURE.md (this file) ✓
- DECISIONS.md ✓

**Pending (Research Stage):**
- Detailed database schema design
- API endpoint specification
- PWA service worker architecture
- Offline sync strategy
- M-Pesa integration design

---

## CHANGE LOG

| Date | Decision | Changed By | Status |
|------|----------|------------|--------|
| 2026-01-28 | Technology stack locked (Django + PostgreSQL + PWA) | Business Owner | APPROVED |
| 2026-01-28 | Multi-business architecture approved | Business Owner | APPROVED |
| 2026-01-28 | Mobile-first primary user requirement | Business Owner | APPROVED |
| 2026-01-28 | Double-entry financial system | Business Owner | APPROVED |
| 2026-01-28 | Budget: $15,000, Timeline: 3 months MVP | Business Owner | APPROVED |

---

**Next Steps:**
1. Research agent to investigate pending decisions
2. Create detailed technical specifications
3. Finalize all architecture choices
4. Proceed to refactor stage (if needed) or implementation

**END OF ARCHITECTURE DOCUMENT**

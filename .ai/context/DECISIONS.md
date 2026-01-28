# PROJECT DECISIONS LOG

**Project:** Unified Business Management System
**Version:** 0.1.0
**Last Updated:** 2026-01-28

---

## HOW TO USE THIS DOCUMENT

This document captures ALL decisions made throughout the project lifecycle. Each decision includes:

1. **Decision ID** - Unique identifier
2. **Date** - When decision was made
3. **Decision** - What was decided
4. **Made By** - Who made the decision (agent or human)
5. **Status** - APPROVED, PENDING, or SUPERSEDED
6. **Rationale** - Why this decision was made
7. **Impact** - Technical, cost, timeline implications
8. **Locked** - Whether this requires human approval to change

---

## LOCKED DECISIONS (Requires Human Approval to Change)

### DEC-001: Mission Definition Approved

**Decision ID:** DEC-001
**Date:** 2026-01-28
**Decision:** Comprehensive MISSION.md document approved and locked
**Made By:** Business Owner (via escalation esc_mission_definition_20260128_084000)
**Status:** APPROVED - LOCKED
**Escalation:** esc_mission_definition_20260128_084000

**Decision Summary:**
- Project: Unified Business Management System (multi-business ERP)
- 3 Businesses: Water Packaging, Laundry, Retail/LPG
- Primary User: Business owner on mobile phone (90% of operations)
- Stack: Django 5.0+, PostgreSQL, PWA (mobile-first)
- Budget: $15,000 total, $200/month operational
- MVP Timeline: 3 months
- Critical: Record sale in <30 seconds on mobile

**Rationale:**
Comprehensive mission definition provides foundation for all technical decisions. Business owner confirmed all requirements including mobile-first approach, financial constraints, and success criteria.

**Impact:**
- Technical: All architecture decisions must align with mobile-first PWA approach
- Cost: Total budget locked at $15,000, monthly ops at $200
- Timeline: MVP must be delivered by 2026-04-28 (3 months)
- Scope: Must support 3 businesses with independent operations + consolidated financials

**Locked:** YES - Requires explicit human approval to modify mission requirements

**Related Files:**
- /media/munen/muneneENT/ementech-portfolio/tomtin/MISSION.md
- /media/munen/muneneENT/ementech-portfolio/tomtin/.ai/escalations/resolved/esc_mission_definition_20260128_084000.json

---

### DEC-002: Technology Stack Selection

**Decision ID:** DEC-002
**Date:** 2026-01-28
**Decision:** Backend: Django 5.0+, Database: PostgreSQL, Frontend: Mobile-First PWA
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Technical Stack:**
- **Backend:** Django 5.0+ (latest stable)
- **Database:** PostgreSQL 15+
- **Frontend:** Progressive Web App (PWA)
- **Deployment:** Docker on VPS
- **Operating System:** Ubuntu 22.04 LTS

**Rationale:**
- Django: Owner has Django developers available, mature ecosystem, excellent for ERP systems
- PostgreSQL: ACID compliance critical for financial transactions, reliable, proven
- PWA: Works across iOS/Android, installable on home screen, offline capability, no app store approval needed

**Impact:**
- Technical: All development must use Django + PostgreSQL, PWA must be mobile-optimized
- Cost: Open-source stack, predictable VPS hosting ($50-100/month)
- Timeline: Familiar stack may accelerate development
- Skills: Leverages existing Django expertise

**Alternatives Considered:**
- FastAPI (rejected: less familiar to team)
- MySQL/MariaDB (rejected: PostgreSQL chosen for ACID compliance)
- Native mobile apps (rejected: too expensive, cross-platform complexity, app store approval delays)

**Locked:** YES - Changing stack would require significant budget/timeline re-evaluation

---

### DEC-003: Multi-Business Architecture

**Decision ID:** DEC-003
**Date:** 2026-01-28
**Decision:** Unified system supporting 3 independent businesses with consolidated financial core
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Architecture Pattern:**
- **Businesses:**
  1. Water Packaging
  2. Laundry
  3. Retail/LPG
- **Independence:** Each business operates independently (no cross-interference)
- **Consolidation:** Financial core provides unified view across all businesses
- **User:** Business owner accesses all businesses from single dashboard

**Rationale:**
Single owner operating 3 businesses needs:
- Unified view of operations and finances
- Ability to manage all businesses from one mobile interface
- Independent business operations (no data mixing)
- Consolidated reporting for decision-making

**Impact:**
- Technical: Database must support multi-tenant data isolation, shared financial ledger
- UX: Dashboard must show all 3 businesses with ability to drill down
- Security: Owner has access to all, potential future role-based access for staff
- Scalability: Must support adding more businesses without code changes

**Alternatives Considered:**
- Separate systems per business (rejected: owner wants unified view, higher cost)
- Single business logic (rejected: businesses are distinct operations)

**Locked:** YES - Core to business model

---

### DEC-004: Mobile-First Design Philosophy

**Decision ID:** DEC-004
**Date:** 2026-01-28
**Decision:** All UX/UI designed for mobile phone first, desktop support secondary
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Mobile-First Requirements:**
- **Primary Device:** Mobile phone (Android/iOS)
- **Usage:** 90% of operations performed on mobile
- **Screen Size:** Optimize for 320px-428px width (5-7 inch screens)
- **Critical Performance:** Record sale in <30 seconds while serving customer
- **Touch-Optimized:** Minimum 44px touch targets, one-handed operation where possible
- **Offline:** Critical functions work offline, sync when online
- **PWA:** Installable on home screen like native app

**Rationale:**
Business owner operates businesses while serving customers:
- Mobile phone is always with owner
- Often one-handed operation (other hand giving change)
- Customer waiting during recording (< 30 seconds critical)
- Works in various environments (sunlight, noise, poor signal)

**Impact:**
- Technical: All UI components must be mobile-optimized, PWA service workers required
- UX: Desktop support secondary, all features must work on mobile first
- Performance: Bundle size < 5MB, page load < 3 seconds on 4G
- Testing: Must test on real mobile devices (Android + iOS)

**Alternatives Considered:**
- Desktop-first with responsive mobile (rejected: 90% usage on mobile)
- Native mobile apps (rejected: exceeds budget, app store complexity)

**Locked:** YES - Core to user experience and success criteria

---

### DEC-005: Double-Entry Financial System

**Decision ID:** DEC-005
**Date:** 2026-01-28
**Decision:** Universal double-entry ledger for all financial transactions
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Financial Architecture:**
- **System:** Double-entry bookkeeping (every debit has corresponding credit)
- **Ledger:** Universal ledger captures ALL money movements
- **Accounts:** Chart of accounts per business (cash, M-Pesa, bank, revenue, expense)
- **Audit:** Every transaction immutable (reversals only, no deletions)
- **Balancing:** Ledger must always balance

**Rationale:**
- Legal requirement for proper accounting in Kenya
- Audit trail required for 7 years (KRA compliance)
- Accurate P&L per business and consolidated
- Prevents errors and fraud
- Professional business management

**Impact:**
- Technical: Database schema must support double-entry, transaction integrity critical
- Development: All financial operations must be atomic (database transactions)
- Testing: Financial calculations must be 100% accurate (zero tolerance for errors)
- Compliance: Supports tax reporting (VAT, withholding)

**Alternatives Considered:**
- Single-entry accounting (rejected: not compliant, prone to errors)
- Cash-basis only (rejected: doesn't show true financial position)

**Locked:** YES - Compliance and business integrity requirement

---

### DEC-006: M-Pesa Integration

**Decision ID:** DEC-006
**Date:** 2026-01-28
**Decision:** Integrate Safaricom M-Pesa Daraja API for payment processing
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Integration Requirements:**
- **API:** Safaricom Daraja API
- **Features:** STK Push, C2B (Customer to Business)
- **Multi-Till:** Support multiple M-Pesa tills (one per business)
- **Auto-Reconciliation:** Payments auto-create ledger entries
- **Real-Time:** Handle payment callbacks immediately
- **Reliability:** Handle duplicates, failures, reversals

**Rationale:**
- M-Pesa is primary payment method in Kenya
- Customers expect to pay via M-Pesa
- Automatic reconciliation reduces manual work
- Real-time payments improve cashflow visibility

**Impact:**
- Technical: API integration complexity, callback endpoint security, duplicate detection
- Development: Sandbox testing required, error handling critical
- Operations: Till balance reconciliation daily
- UX: Seamless payment experience for customers

**Alternatives Considered:**
- Manual M-Pesa recording (rejected: error-prone, slow, poor UX)
- Third-party payment aggregator (rejected: additional cost, dependency)

**Locked:** YES - Critical business requirement

---

### DEC-007: Budget and Timeline Constraints

**Decision ID:** DEC-007
**Date:** 2026-01-28
**Decision:** Total budget $15,000, MVP delivery in 3 months
**Made By:** Business Owner (defined in MISSION.md)
**Status:** APPROVED - LOCKED

**Financial Constraints:**
- **Total Budget:** $15,000 USD
- **Monthly Operations:** $200/month maximum (hosting, APIs, etc.)
- **MVP Timeline:** 3 months (by 2026-04-28)
- **Full Deployment:** 6 months (enhancements post-MVP)

**Rationale:**
- Budget reflects business scale and expected ROI
- 3-month MVP allows faster time-to-value
- Phased rollout reduces risk
- Monthly operational cost ensures long-term sustainability

**Impact:**
- Technical: Must use cost-effective open-source tools, VPS not cloud services
- Scope: MVP focuses on core features (Water → Laundry → Retail)
- Prioritization: Mobile-first, financial core, basic BI in MVP
- Trade-offs: Advanced features deferred to Phase 2 (custom reports, advanced analytics, SMS)

**Alternatives Considered:**
- Higher budget for faster delivery (rejected: business constraint)
- Longer timeline for more features (rejected: need operational efficiency sooner)

**Locked:** YES - Business constraints

---

### DEC-P01: Frontend Framework Selection - React 18

**Decision ID:** DEC-P01
**Date:** 2026-01-28
**Decision:** React 18 selected as frontend framework for mobile-first PWA
**Made By:** Business Owner (via escalation esc_frontend_framework_20260128_153000)
**Status:** APPROVED - LOCKED
**Escalation:** esc_frontend_framework_20260128_153000

**Decision Summary:**
- Framework: React 18 with hooks
- Bundle Size: 165-200KB (minified + gzipped)
- Build Tool: Vite 5.0+ (for fast development)
- State Management: TBD (Zustand or Redux recommended)
- Routing: React Router v6

**Rationale:**
Business owner selected React 18 despite research recommendation of Vue.js 3. Key factors:
- Largest ecosystem of UI libraries and integrations
- Extensive community support and documentation
- Strong long-term viability (Meta backing)
- More developers familiar with React globally

**Accepted Tradeoffs:**
- Larger bundle size (165-200KB vs Vue.js 45-60KB) requires optimization
- Steeper learning curve for Django developers (2-3 weeks vs 1-2 weeks)
- Tighter 3-month timeline (no buffer, requires aggressive optimization)
- More configuration decisions and boilerplate code

**Impact:**
- **Technical:** Must implement bundle optimization (code splitting, lazy loading, tree shaking)
- **Timeline:** 2-3 weeks needed for React training for Django developers
- **Performance:** Requires optimization to achieve < 3 second 4G load target
- **Cost:** May need additional development time for optimization work

**Mitigation Strategy:**
1. Use Vite for fast development and optimized production builds
2. Implement aggressive code splitting (route-based, component-based)
3. Use lazy loading for heavy components (charts, data grids)
4. Consider simpler state management (Zustand) to reduce learning curve
5. Schedule 2-3 weeks developer training in Sprint 1
6. Prototype critical mobile flows early to validate performance

**Alternatives Considered:**
- **Vue.js 3 (Research Recommendation):** Smaller bundle (45-60KB), easier learning curve, safer timeline - REJECTED by owner
- **Svelte 5:** Smallest bundle (15-25KB), best performance - REJECTED due to immature ecosystem

**Locked:** YES - Frontend framework is foundational; changing would require significant rework

**Related Files:**
- /media/munen/muneneENT/ementech-portfolio/tomtin/docs/research/research_frontend_framework_20260128.md
- /media/munen/muneneENT/ementech-portfolio/tomtin/.ai/escalations/resolved/esc_frontend_framework_20260128_153000.json

**Next Steps:**
1. Research React-specific mobile UI library (Material-UI, Chakra UI, Ant Design Mobile)
2. Define bundle optimization strategy
3. Create React training plan for Django developers
4. Set up React + Vite development environment

---

## PENDING DECISIONS (To be Made in Research Stage)

### DEC-P02: Mobile UI Component Library
**Status:** PENDING RESEARCH - NOW REACT-SPECIFIC
**Options:** Material-UI, Chakra UI, Ant Design Mobile, React Native Paper
**Decision Maker:** Research Agent → Human Approval
**Criteria:** Touch optimization, mobile-first patterns, bundle size impact

### DEC-P03: Offline Data Storage Strategy
**Status:** PENDING RESEARCH
**Options:** IndexedDB, LocalStorage, Dexie.js, PouchDB
**Decision Maker:** Research Agent → Human Approval
**Criteria:** Storage limits, sync complexity, mobile browser support

### DEC-P04: Task Queue System
**Status:** PENDING RESEARCH
**Options:** Celery + Redis, Django-RQ, Dramatiq
**Decision Maker:** Research Agent → Human Approval
**Criteria:** Integration complexity, performance, monitoring

### DEC-P05: Chart/Visualization Library
**Status:** PENDING RESEARCH
**Options:** Chart.js, Recharts, Victory, ApexCharts
**Decision Maker:** Research Agent → Human Approval
**Criteria:** Mobile rendering, touch interaction, bundle size, offline support

---

## DECISION-MAKING PROCESS

### How Decisions Are Made

1. **Strategic Decisions** (Technology, Architecture, Scope)
   - Made by: Business Owner (human)
   - Process: Escalation → Research → Human Decision → Lock in documentation
   - Status: LOCKED

2. **Technical Decisions** (Frameworks, Libraries, Tools)
   - Made by: Research Agent with recommendation
   - Process: Research → Recommendation → Human Approval → Lock in documentation
   - Status: LOCKED after approval

3. **Implementation Decisions** (Code patterns, approaches)
   - Made by: Implementing agent (refactor/implementation)
   - Process: Decision → Document in DECISIONS.md → Log in AGENT_HISTORY
   - Status: Can be superseded by better approaches

### Changing a Locked Decision

**Process:**
1. Create escalation explaining why change is needed
2. Document impact (cost, timeline, technical debt)
3. Provide alternatives with trade-offs
4. Human reviews and approves/rejects
5. If approved: Update decision status to SUPERSEDED, create new decision
6. Update ARCHITECTURE.md and MISSION.md if needed

**Example Escalation for Decision Change:**
```
Topic: Change Frontend Framework from React to Vue.js
Reason: Research shows Vue.js offers 30% smaller bundle size
Impact: Reduces initial load time by 1.2 seconds on 4G
Cost Impact: None (both open source)
Timeline Impact: None (team knows both)
Request: Approval to switch to Vue.js
```

---

## DECISION LOG INDEX

| ID | Date | Decision | Made By | Status | Locked |
|----|------|----------|---------|--------|--------|
| DEC-001 | 2026-01-28 | Mission Definition Approved | Business Owner | APPROVED | YES |
| DEC-002 | 2026-01-28 | Technology Stack Selection | Business Owner | APPROVED | YES |
| DEC-003 | 2026-01-28 | Multi-Business Architecture | Business Owner | APPROVED | YES |
| DEC-004 | 2026-01-28 | Mobile-First Design Philosophy | Business Owner | APPROVED | YES |
| DEC-005 | 2026-01-28 | Double-Entry Financial System | Business Owner | APPROVED | YES |
| DEC-006 | 2026-01-28 | M-Pesa Integration | Business Owner | APPROVED | YES |
| DEC-007 | 2026-01-28 | Budget and Timeline Constraints | Business Owner | APPROVED | YES |
| DEC-P01 | 2026-01-28 | Frontend Framework - React 18 | Business Owner | APPROVED | YES |

---

**END OF DECISIONS LOG**

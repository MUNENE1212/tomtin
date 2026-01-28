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

---

### DEC-P02: Mobile UI Component Library - Mantine UI

**Decision ID:** DEC-P02
**Date:** 2026-01-28
**Decision:** Mantine UI selected as React UI component library for mobile + desktop PWA
**Made By:** Business Owner (via escalation esc_ui_library_20260128_163000)
**Status:** APPROVED - LOCKED
**Escalation:** esc_ui_library_20260128_163000

**Decision Summary:**
- Library: Mantine UI v7+
- Bundle Size: ~70-200KB (tree-shaken, fully modular)
- Scope: Single library for both mobile AND desktop (no dual library needed)
- Integration: React 18 + Vite 5.0+
- TypeScript: Native support (first-class TypeScript library)

**Rationale:**
Business owner selected Mantine UI after comparing against research recommendation (Ant Design Mobile) and alternatives (Chakra UI, Material-UI). Key factors:
- **Single library for mobile + desktop** - No need for dual libraries
- **Smallest bundle size** (70-200KB vs 200-300KB Chakra vs 300-400KB Material-UI)
- **English documentation** - No language barrier for team
- **Built-in ERP components** - Data grid, forms, charts, hooks included
- **Responsive by design** - Works on 320px mobile AND desktop
- **Excellent React 18 + Vite support** - Modern build tooling

**Accepted Tradeoffs:**
- Need to build custom bottom navigation component (2-3 days)
- No pre-built mobile-specific patterns like antd-mobile's bottom nav
- Newer library than Material-UI (but mature and stable, active development)

**Impact:**
- **Technical:** Single UI library for all screen sizes, responsive layouts via AppShell
- **Timeline:** Minimal impact (0-7 days for custom components vs 8-13 days for Ant Design Mobile)
- **Bundle:** 70-200KB + React 165-200KB = 235-400KB total (well under budget)
- **Learning:** TypeScript-first, English docs - easier for Django developers

**Mitigation Strategy:**
1. Use Mantine's `AppShell` component for responsive layouts
2. Use `Drawer` for mobile hamburger menu navigation
3. Build custom bottom nav using Mantine components (2-3 days)
4. Leverage `useMediaQuery` hook for responsive behavior detection
5. Use built-in `@mantine/form` for form validation
6. Use built-in `@mantine/charts` for data visualization
7. Use built-in data tables for ERP data display

**Stack Integration:**
```
React 18 (DEC-P01)
├── Mantine UI v7+ (@mantine/core)
├── @mantine/hooks (react hooks library)
├── @mantine/form (form validation)
├── @mantine/charts (charts, powered by Recharts)
└── Vite 5.0+ (build tool with tree-shaking)
```

**Alternatives Considered:**
- **Ant Design Mobile (Research Recommendation):** Purpose-built for mobile, but required dual library for desktop (+8-13 days) - REJECTED
- **Chakra UI:** Good single library option, but larger bundle (200-300KB) and less ERP components - REJECTED
- **Material-UI:** Most mature, but too large (400-500KB) and desktop-first - REJECTED

**Locked:** YES - UI library is foundational; changing would require rebuilding all components

**Related Files:**
- /media/munen/muneneENT/ementech-portfolio/tomtin/docs/research/research_mobile_ui_library_20260128.md
- /media/munen/muneneENT/ementech-portfolio/tomtin/.ai/escalations/resolved/esc_ui_library_20260128_163000.json

**Next Steps:**
1. Document mobile component architecture (bottom nav build plan)
2. Define responsive layout strategy with AppShell
3. Set up Mantine + Vite development environment
4. Create proof-of-concept mobile + desktop layouts

---

---

### DEC-P03: Offline Data Storage Strategy - Dexie.js

**Decision ID:** DEC-P03
**Date:** 2026-01-28
**Decision:** Dexie.js selected as offline storage layer for mobile PWA
**Made By:** Business Owner (via escalation esc_offline_storage_20260128_170000)
**Status:** APPROVED - LOCKED
**Escalation:** esc_offline_storage_20260128_170000

**Decision Summary:**
- Library: Dexie.js v3+ (modern wrapper around IndexedDB)
- Bundle Size: 20KB minified + gzipped
- Storage Capacity: ~500MB+ on mobile browsers
- Integration: dexie-react-hooks for React 18
- Pattern: Queue-and-replay sync (offline → online)

**Rationale:**
Business owner selected Dexie.js as the offline storage strategy. Key factors:
- **Zero data loss guarantee** via IndexedDB transactional writes (atomic, all-or-nothing)
- **Excellent React 18 integration** with official `dexie-react-hooks` package (`useLiveQuery()`)
- **Fast implementation** - 2-3 weeks total, fits 3-month MVP timeline
- **Tiny bundle** - 20KB adds minimal overhead (React 165KB + Mantine 200KB + Dexie 20KB = 385KB)
- **Massive capacity** - ~500MB storage, handles 500+ transactions easily (~5-10MB)
- **Proven technology** - 13K GitHub stars, 400K weekly NPM downloads
- **Django developer friendly** - Promise-based API, TypeScript support, 3-5 day learning curve

**Critical Requirements Met:**
- ✅ Zero data loss for financial transactions (non-negotiable)
- ✅ Survives browser crashes and device restarts
- ✅ Works on iOS Safari and Android Chrome
- ✅ Queue transactions offline, sync when online
- ✅ User sees sync status (pending/synced/failed)

**Impact:**
- **Technical:** IndexedDB wrapper provides transactional reliability with simple API
- **Timeline:** 2-3 weeks implementation (Week 1: learning/design, Week 2: core storage, Week 3: React integration)
- **Bundle:** +20KB (385KB total - well under 5MB PWA budget)
- **Data Integrity:** Atomic writes, crash recovery, duplicate detection via idempotency keys

**Data Architecture:**
1. **Offline ID Generation** - UUID v4 for unique transaction IDs
2. **Atomic Transaction Writes** - All-or-nothing via IndexedDB transactions
3. **Queue-and-Replay Sync** - Queue locally, auto-sync when connection restored
4. **Crash Recovery** - Auto-verification and recovery on app restart
5. **Duplicate Detection** - Idempotency keys prevent double submission
6. **Sync Status Visibility** - Real-time UI updates (pending/synced/failed)
7. **Retry Strategy** - Auto-retry on reconnect, exponential backoff

**Storage Schema (Planned):**
- `transactions` - Offline sales, expenses, deposits, withdrawals
- `products` - Product catalog (cached from server)
- `customers` - Customer data (cached from server)
- `sync_queue` - Ordered queue of pending actions to sync
- `sync_status` - Tracking sync state (last sync, pending count, failures)

**Stack Integration:**
```
React 18 (DEC-P01)
├── Mantine UI (DEC-P02)
├── Dexie.js v3+ (@mantine/core independent)
│   ├── dexie-react-hooks (useLiveQuery)
│   └── IndexedDB (browser storage)
└── Vite 5.0+ (build tool)
```

**Alternatives Considered:**
- **Raw IndexedDB (8.35/10):** Same reliability but complex callback API, +1-2 weeks timeline, no React hooks - REJECTED
- **LocalStorage (5.05/10):** Only 5-10MB capacity, not transactional (data loss risk), synchronous (blocks UI) - REJECTED
- **PouchDB (7.85/10):** 140KB bundle, bi-directional sync overkill, steep learning curve - REJECTED
- **RxDB (7.85/10):** 100-150KB bundle, reactive programming complexity - REJECTED

**Locked:** YES - Offline storage is foundational for zero data loss requirement

**Related Files:**
- /media/munen/muneneENT/ementech-portfolio/tomtin/docs/research/research_offline_storage_20260128.md
- /media/munen/muneneENT/ementech-portfolio/tomtin/.ai/escalations/resolved/esc_offline_storage_20260128_170000.json

**Next Steps:**
1. Design Dexie.js schema for all offline entities
2. Document sync architecture and conflict resolution
3. Plan React hooks for offline operations (useOfflineTransaction, etc.)
4. Implement sync queue and retry logic
5. Create sync status UI components

---

## PENDING DECISIONS (To be Made in Research Stage)

### DEC-P04: Task Queue System
**Status:** PENDING RESEARCH
**Options:** Celery + Redis, Django-RQ, Dramatiq
**Decision Maker:** Research Agent → Human Approval
**Criteria:** Integration complexity, performance, monitoring

### DEC-P05: Chart/Visualization Library
**Status:** ALREADY DECIDED (included with Mantine UI - DEC-P02)
**Selection:** @mantine/charts (powered by Recharts)
**Decision Maker:** Included with Mantine UI selection
**Notes:** Mantine Charts provides mobile-optimized charts powered by Recharts. No additional library needed.

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
| DEC-P02 | 2026-01-28 | UI Component Library - Mantine UI | Business Owner | APPROVED | YES |
| DEC-P03 | 2026-01-28 | Offline Storage - Dexie.js | Business Owner | APPROVED | YES |
| DEC-P05 | 2026-01-28 | Chart Library - @mantine/charts | Mantine UI | APPROVED | YES |

---

**END OF DECISIONS LOG**

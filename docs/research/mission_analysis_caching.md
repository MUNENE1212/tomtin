# Mission Analysis: Caching Strategy Research

**Project:** Unified Business Management System (ERP)
**Date:** 2026-01-28
**Research Topic:** Multi-Layer Caching Strategy for Django 5.0+ Mobile-First PWA ERP

---

## MISSION REQUIREMENTS EXTRACTION

### Core Goal
Build a production-grade ERP system enabling one business owner to efficiently operate three distinct businesses (Water Packaging, Laundry, Retail/LPG) from a single integrated platform, with **mobile phone as primary device**.

### Critical Requirements Impacting Caching Strategy

#### 1. VPS Resource Constraints (CRITICAL)
**Constraint:** 4GB RAM VPS, 2 CPU, $50-100/month hosting budget
- Total monthly operations budget: $200 (includes VPS, APIs, monitoring)
- Redis already allocated 50-200MB for Django-RQ (task queue decision pending)
- Django-RQ workers: 50-100MB per worker (4-6 workers = 200-600MB)
- PostgreSQL, Django, Nginx also consume RAM
- **Cache must fit within remaining RAM budget**

#### 2. Mobile Performance Requirements (CRITICAL)
**Constraint:** Fast API response times on mobile networks
- API response time target: < 500ms (p95)
- Page load target: < 3 seconds on 4G
- Sale recording: < 30 seconds total
- Primary device: Mobile phone (320px-428px width)
- Connection: 4G/WiFi (unstable at times)
- **Cache must reduce API latency and data transfer**

#### 3. Data Freshness Requirements (CRITICAL)
**Context:** POS/ERP system with frequent data changes
- Inventory levels change with every sale
- Prices updated regularly
- Customer data changes daily
- Real-time dashboard requirements (today's revenue, stock levels)
- **Cache invalidation must be simple and reliable**

#### 4. Offline Capability (CRITICAL)
**Requirement:** Critical functions work offline
- Dexie.js selected for offline storage (IndexedDB wrapper)
- Service Worker for PWA caching
- Queue-and-replay sync pattern
- **Server-side cache must support offline-first architecture**

#### 5. Financial Data Integrity (NON-NEGOTIABLE)
**Requirement:** Zero data loss tolerance for financial transactions
- Double-entry accounting system
- Every money movement recorded in universal ledger
- Audit trail for 7 years (KRA compliance)
- **Cache must NEVER serve stale financial data**

---

## CACHING USE CASES ANALYSIS

### Use Case 1: API Response Caching (HIGH PRIORITY)
**Data:** Product lists, price lists, customer data
**Change Frequency:** Low (products/prices change daily/weekly)
**Access Frequency:** High (every product selection, customer lookup)
**Cache Duration:** 5-15 minutes (acceptable staleness)
**RAM Impact:** Medium (product catalog = 1-5MB)

### Use Case 2: Query Result Caching (MEDIUM PRIORITY)
**Data:** Expensive reports (sales by product, revenue trends)
**Change Frequency:** Low (historical data doesn't change)
**Access Frequency:** Medium (dashboard views, reports)
**Cache Duration:** 15-60 minutes (historical data)
**RAM Impact:** High (report results can be 5-20MB)

### Use Case 3: Session Storage (HIGH PRIORITY)
**Data:** User sessions (if using session-based auth)
**Change Frequency:** Medium (session updates on activity)
**Access Frequency:** High (every API call)
**Cache Duration:** 2 hours (mobile session timeout)
**RAM Impact:** Low (5-10KB per session, ~20 users = 1MB)

### Use Case 4: Page Fragment Caching (LOW PRIORITY)
**Data:** Dashboard components, BI widgets
**Change Frequency:** Real-time to hourly
**Access Frequency:** High (dashboard views)
**Cache Duration:** 1-5 minutes (near real-time)
**RAM Impact:** Medium (100-500KB per fragment)

### Use Case 5: Mobile PWA Caching (HIGH PRIORITY)
**Data:** API responses on mobile device
**Change Frequency:** Varies by endpoint
**Access Frequency:** Very high (offline + online)
**Cache Duration:** Varies (5 min for real-time, 24h for reference data)
**Storage:** IndexedDB (via Dexie.js) - no server RAM impact

---

## CONSTRAINTS VERIFICATION

### Budget Constraints
- ✅ Open-source caching solutions only (Redis, Memcached)
- ✅ No cloud caching services (AWS ElastiCache, Azure Cache)
- ✅ Must fit within $200/month total ops budget
- ✅ VPS hosting: $50-100/month

### Timeline Constraints
- ✅ MVP delivery: 3 months (2026-04-28)
- ✅ Must implement caching in Sprint 1-2 (foundation phase)
- ✅ Simple cache invalidation (no complex architecture)

### Technical Constraints
- ✅ Must work with Django 5.0+
- ✅ Must work with PostgreSQL
- ✅ Must support mobile PWA (Service Worker, Cache API)
- ✅ Must integrate with Django REST Framework
- ✅ Django developers (Python expertise)

### Performance Constraints
- ✅ API response: < 500ms
- ✅ Mobile page load: < 3 seconds on 4G
- ✅ Support 20 concurrent users
- ✅ Handle 500+ transactions/day

### Data Integrity Constraints
- ✅ Zero data loss for financial transactions
- ✅ No stale financial data served
- ✅ Cache invalidation on data changes
- ✅ Audit trail for cache misses (optional)

---

## VPS RESOURCE BUDGET CALCULATION

### Total RAM: 4GB (4096MB)

#### Known Allocations (Based on Task Queue Research):
1. **PostgreSQL:** 500-1000MB (tunable, needs RAM for caching query results)
2. **Django (Gunicorn 2-4 workers):** 200-400MB (50-100MB per worker)
3. **Django-RQ (4 workers recommended):** 200-400MB (50-100MB per worker)
4. **Redis (for Django-RQ):** 50-200MB (task queue data)
5. **Nginx:** 20-50MB (reverse proxy)
6. **OS + Overhead:** 200-400MB (Ubuntu 22.04 LTS)

**Current Usage:** 1170-2450MB (29-60% of 4GB)

#### Remaining RAM for Additional Caching:
- **Best Case:** 4096 - 1170 = **2926MB available**
- **Worst Case:** 4096 - 2450 = **1646MB available**
- **Conservative Estimate:** **2000MB available for additional caching**

**Critical Question:** Can we use Redis for BOTH task queue AND caching without exceeding RAM budget?

---

## SUCCESS CRITERIA FOR CACHING STRATEGY

### Must Have (Non-Negotiable):
1. ✅ Fits within 4GB VPS RAM constraint (with Django-RQ + Redis)
2. ✅ Reduces API response time to < 500ms (p95)
3. ✅ Simple cache invalidation (Django developers can implement)
4. ✅ Supports mobile PWA caching (Service Worker integration)
5. ✅ Never serves stale financial data
6. ✅ Works offline-first (PWA Service Worker + Dexie.js)

### Should Have (Important):
7. ✅ Minimal memory overhead (< 500MB additional RAM)
8. ✅ Easy Django integration (native Django cache framework)
9. ✅ Cache warming capabilities (pre-load frequently accessed data)
10. ✅ Cache statistics/monitoring (hit rate, memory usage)
11. ✅ Supports cache versioning (data migrations)

### Nice to Have (If Possible):
12. ✅ Redis already used for Django-RQ (reuse existing infrastructure)
13. ✅ Supports cache tagging (group invalidation)
14. ✅ Automatic cache expiration
15. ✅ Distributed caching (future scalability)

---

## RESEARCH QUESTIONS TO ANSWER

### Primary Questions:
1. **Should we use Redis for both task queue AND caching?** (memory implications)
2. **What's the optimal multi-layer caching strategy?** (server + PWA)
3. **How do we invalidate cache for frequently changing POS data?** (inventory, prices)
4. **Can we achieve < 500ms API response with database alone?** (is caching necessary?)

### Secondary Questions:
5. **How much RAM will Redis consume for both task queue + cache?**
6. **What cache duration is appropriate for different data types?**
7. **How do we implement cache invalidation signals in Django?**
8. **What's the implementation timeline for caching strategy?**

---

## KEY DECISIONS ALREADY MADE

### Locked Decisions (From DECISIONS.md):
- **DEC-002:** Django 5.0+, PostgreSQL, PWA (mobile-first)
- **DEC-004:** Mobile-first design philosophy (90% operations on mobile)
- **DEC-005:** Double-entry financial system (zero data loss tolerance)
- **DEC-P01:** React 18 frontend framework
- **DEC-P02:** Mantine UI component library
- **DEC-P03:** Dexie.js for offline storage (IndexedDB)
- **DEC-P04:** Django-RQ for task queue (pending human approval, uses Redis)

### Implications for Caching:
1. **Django integration:** Must use Django's cache framework
2. **Mobile-first:** PWA Service Worker caching is critical
3. **Dexie.js offline storage:** Server cache must support offline-first sync
4. **Redis already present:** Can reuse for caching (if RAM permits)
5. **Financial data integrity:** Cannot cache real-time financial data

---

## EVALUATION CRITERIA WEIGHTING

Based on mission requirements and constraints:

| Criterion | Weight | Justification |
|-----------|--------|---------------|
| **VPS Resource Fit** | 30% | 4GB RAM is hard constraint; exceeding risks system stability |
| **Django Integration** | 20% | Django developers need simple implementation |
| **Cache Invalidation** | 20% | POS data changes frequently; stale data unacceptable |
| **Mobile/PWA Support** | 15% | 90% usage on mobile; Service Worker integration critical |
| **Complexity** | 10% | 3-month timeline; no time for complex architecture |
| **Cost** | 5% | All open-source, but RAM affects VPS sizing |

**Total:** 100%

---

## MISSION ALIGNMENT SUMMARY

### How Caching Strategy Supports Mission:

1. **Mobile Performance (< 3s page load, < 500ms API):**
   - Server-side cache reduces database query time
   - PWA cache reduces network calls (works offline)
   - Multi-layer strategy provides defense in depth

2. **VPS Resource Constraints (4GB RAM, $200/month):**
   - Reuse Redis for both task queue + caching (efficient)
   - Monitor RAM usage to prevent OOM (out of memory)
   - Simple architecture reduces operational complexity

3. **POS/ERP Data Freshness:**
   - Short TTL for real-time data (inventory: 1-5 min)
   - Longer TTL for reference data (products: 15-60 min)
   - Cache invalidation on data changes (Django signals)

4. **Financial Data Integrity:**
   - No caching for financial transaction endpoints
   - Cache only for read-heavy operations (reports, dashboards)
   - Explicit cache invalidation for financial summaries

5. **Offline Capability:**
   - PWA Service Worker caches API responses
   - Dexie.js stores offline transactions
   - Server cache supports sync reconciliation

---

## END OF MISSION ANALYSIS

**Next Step:** Research caching options (Redis, Memcached, Database Cache, File-Based, Varnish, PWA Service Worker) against these requirements and create comprehensive comparison matrix.

# Mission Analysis: Task Queue System Research

**Project:** Unified Business Management System (ERP)
**Date:** 2026-01-28
**Research Focus:** Task Queue System for Django 5.0+ ERP on VPS

---

## Mission Requirements Impact Analysis

### Core Mission Goals (from MISSION.md)

**1. Multi-Business ERP System**
- Water Packaging, Laundry, Retail/LPG businesses
- Unified system with independent operations
- Single owner managing all businesses

**2. Financial Criticality**
- Zero tolerance for financial transaction errors
- Double-entry accounting enforced
- All money movements recorded immutably
- Audit trail for 7 years (KRA compliance)

**3. M-Pesa Integration (DEC-006)**
- Real-time payment callbacks (STK Push, C2B)
- Multiple till numbers (one per business)
- Auto-reconciliation with ledger
- Handle duplicates, failures, reversals
- **IMPACT: Task queue MUST process payment callbacks reliably**

**4. VPS Constraints (DEC-002, CONSTRAINTS.md)**
- Budget: $50-100/month VPS
- Specs: 4GB RAM, 2 CPU (to be confirmed)
- Total operational budget: $200/month (includes Redis, task queue worker)
- No cloud services with unpredictable costs
- Docker deployment required
- **IMPACT: Task queue must work reliably on 4GB RAM with Django + PostgreSQL + Redis**

**5. 3-Month MVP Timeline (DEC-007)**
- Sprint 3-4 (Weeks 5-8): Water business + M-Pesa integration
- Sprint 5-6 (Weeks 9-12): Laundry + Retail + BI + deployment
- **IMPACT: Task queue must be implemented quickly (< 1 week)**

---

## Task Queue Use Cases (from User Request)

### Critical (MVP - Must Work)

1. **M-Pesa Payment Processing**
   - Callback handling from Safaricom Daraja API
   - Payment verification and validation
   - Auto-create ledger entries on successful payment
   - Duplicate detection (prevent double payment processing)
   - **Reliability:** CRITICAL - financial transactions
   - **Frequency:** 50-200 times/day (3 businesses)
   - **Execution Time:** < 2 seconds

2. **Report Generation**
   - PDF reports (Profit & Loss, Balance Sheet, Cashflow)
   - Excel exports (sales, inventory, expenses)
   - Can take 10-30 seconds to generate
   - **Reliability:** HIGH (user waits for download)
   - **Frequency:** 5-20 times/day
   - **Execution Time:** 10-30 seconds

3. **Scheduled Tasks**
   - Daily backups (end-of-day)
   - End-of-day closing processes
   - Daily report generation (email if configured)
   - **Reliability:** HIGH (operational requirement)
   - **Frequency:** Scheduled (daily, weekly)
   - **Execution Time:** Variable (30 seconds - 5 minutes)

### Important (MVP - Should Work)

4. **Data Sync**
   - Sync data between businesses (consolidated reporting)
   - Backup jobs (database dumps, cloud backup if available)
   - **Reliability:** MEDIUM
   - **Frequency:** Scheduled
   - **Execution Time:** Variable

5. **Background Calculations**
   - BI analytics (daily profit calculations)
   - Inventory valuation
   - Customer balance updates
   - **Reliability:** MEDIUM (can be recalculated)
   - **Frequency:** Scheduled or on-demand
   - **Execution Time:** Variable (5-60 seconds)

### Future (Phase 2 - Post-MVP)

6. **Email Notifications**
   - Send reports, alerts
   - Scheduled daily/weekly emails
   - **Reliability:** MEDIUM (can retry later)
   - **Frequency:** Scheduled
   - **Execution Time:** Variable

---

## Technical Constraints Impact

### VPS Resource Constraints (4GB RAM)

**Django + PostgreSQL Base Memory Usage:**
- Django (Gunicorn): ~200-400MB per worker (typically 2-3 workers)
- PostgreSQL: ~500MB-1GB (depending on database size and connections)
- Nginx: ~50-100MB
- **Subtotal (without task queue): ~1.5-2.5GB**

**Available for Task Queue:**
- **Remaining RAM: ~1.5-2.5GB**
- Must share with:
  - Redis (~100-500MB)
  - Task queue worker processes
  - System overhead

**IMPACT:**
- Task queue CANNOT consume > 1GB RAM
- Worker processes must be memory-efficient
- Worker pool size limited (likely 2-4 workers max)
- Memory leaks unacceptable

### Django Developer Expertise

**Mission Constraint (from MISSION.md):**
- "Owner has Django developers available"
- **IMPACT:** Task queue should have good Django integration
- Libraries with Django-specific packages preferred
- Documentation should be Django-friendly

### Operational Budget ($200/month)

**Cost Breakdown:**
- VPS: $50-100/month
- Domain + SSL: ~$10-20/year (negligible)
- **Remaining for infrastructure: ~$100/month**

**Task Queue Infrastructure Costs:**
- Redis: Already needed for Django caching/session storage (~100-500MB RAM)
- Task queue worker: Uses existing VPS (no additional cost IF memory-efficient)
- Monitoring tools: Prefer free/open-source (Flower, rq-dashboard)

**IMPACT:**
- Cannot add additional VPS for task queue (budget constraint)
- Cannot use paid monitoring services (Sentry APM, DataDog)
- Must use free monitoring tools

---

## Specific Task Queue Requirements

### 1. Django Integration (CRITICAL)

**Requirements:**
- Django 5.0+ compatible
- Clean integration with Django ORM
- Support Django settings/configuration
- Django admin integration (optional but nice)
- Works with Django transactions
- Error handling compatible with Django exception handling

### 2. Resource Usage (CRITICAL)

**Requirements:**
- Worker memory: < 100MB per worker process
- Worker CPU: Low idle usage, burst when processing tasks
- Worker pool: Configurable (start with 2-4 workers on 4GB VPS)
- Memory leaks: None acceptable (will crash VPS in 24-48 hours)

### 3. Monitoring (HIGH)

**Requirements:**
- See what tasks are currently running
- See failed tasks with error messages
- See task retry attempts
- View task queue depth (backlog)
- Task execution history (at least last 24 hours)
- **Free monitoring tool available** (web UI preferred)

### 4. Reliability (CRITICAL for Financial Tasks)

**Requirements:**
- Task durability: Tasks not lost if worker crashes
- Retry mechanism: Configurable retry with exponential backoff
- Idempotency: Tasks can be safely retried (especially M-Pesa callbacks)
- Error handling: Failed tasks logged with full context
- Worker recovery: Auto-restart on crash (supervisord/systemd)

### 5. Complexity (MEDIUM-HIGH)

**Requirements:**
- Django developers should understand system within 1 week
- Configuration should be straightforward
- Debugging failed tasks should be easy
- Documentation should be comprehensive
- Community support available (Stack Overflow, GitHub issues)

### 6. Cost (FREE)

**Requirements:**
- Open-source (MIT/BSD/Apache license)
- No additional infrastructure costs beyond VPS
- Monitoring tools must be free/open-source
- No commercial/enterprise features required

---

## Task Priorities for Research

### 1. Reliability (40% weight)
- Task durability ( broker persistence)
- Worker crash recovery
- Retry mechanisms
- Error handling
- Idempotency support

### 2. Resource Usage (25% weight)
- RAM consumption per worker
- CPU usage (idle and processing)
- VPS fit (4GB RAM constraint)
- Worker pool configuration flexibility

### 3. Django Integration (15% weight)
- Django 5.0+ compatibility
- Django ORM integration
- Django settings integration
- Django-specific packages available
- Learning curve for Django developers

### 4. Monitoring (10% weight)
- Built-in monitoring capabilities
- Free monitoring tools available
- Debugging ease
- Task visibility (running, pending, failed)

### 5. Complexity (10% weight)
- Setup time (< 1 week preferred)
- Documentation quality
- Learning curve
- Community support

---

## Success Criteria

The recommended task queue system MUST:

1. ✅ Work reliably on 4GB RAM VPS (with Django + PostgreSQL + Redis)
2. ✅ Process M-Pesa callbacks with zero data loss (financial criticality)
3. ✅ Provide visibility into task status (running, failed, retrying)
4. ✅ Be implementable within 1 week (MVP timeline)
5. ✅ Have Django 5.0+ integration
6. ✅ Offer free monitoring tools
7. ✅ Support scheduled tasks (daily backups, end-of-day closing)
8. ✅ Allow 2-4 concurrent workers on 4GB VPS

The recommended task queue system SHOULD:

1. ✅ Have excellent documentation
2. ✅ Have strong community support (Stack Overflow, GitHub)
3. ✅ Be actively maintained (updates within last 12 months)
4. ✅ Support task prioritization (M-Pesa callbacks > background calculations)
5. ✅ Provide worker health monitoring
6. ✅ Integrate with Docker deployment

---

## Risk Factors

### High Risk (Must Address)

1. **Memory Leaks** - Worker consuming RAM until VPS crashes
   - **Mitigation:** Choose mature library with proven stability
   - **Monitoring:** RAM alerts at 3.5GB/4GB

2. **Lost M-Pesa Callbacks** - Payment not recorded
   - **Mitigation:** Persistent broker (Redis), confirmable tasks
   - **Monitoring:** Failed task alerts, daily reconciliation

3. **Worker Crash Loop** - Worker keeps crashing, tasks pile up
   - **Mitigation:** Process supervisor (systemd/supervisord), crash logging
   - **Monitoring:** Worker uptime monitoring

### Medium Risk (Should Address)

1. **Task Duplication** - Same task executed twice
   - **Mitigation:** Idempotent task design, idempotency keys
   - **Impact:** Financial transactions MUST be idempotent

2. **Queue Backup** - Tasks accumulate faster than processing
   - **Mitigation:** Worker pool sizing, task prioritization
   - **Monitoring:** Queue depth alerts

3. **Redis Failure** - Broker down, tasks not processing
   - **Mitigation:** Redis persistence (AOF), monitoring
   - **Recovery:** Redis restart, worker auto-recovery

---

## Research Focus Areas

Based on mission requirements and constraints, research must focus on:

1. **Celery + Redis** - Industry standard, but memory-heavy?
2. **Django-RQ** - Simpler alternative, better for VPS?
3. **Dramatiq** - Modern, lightweight alternative
4. **Django Background Tasks** - No Redis needed, but reliable?
5. **Huey** - Lightweight option, good monitoring?

**Elimination Criteria:**
- Eliminate any option requiring > 1GB RAM for workers
- Eliminate any option without free monitoring tools
- Eliminate any option not compatible with Django 5.0+
- Eliminate any option lacking active maintenance

**Scoring Criteria:**
- VPS Resource Fit (0-10): Can it run on 4GB VPS?
- Django Integration (0-10): How well does it work with Django?
- Monitoring (0-10): Can we see what's running/failed?
- Reliability (0-10): Task durability, retry mechanisms?
- Complexity (0-10): Django developers learning curve?
- Maturity (0-10): Community size, maintenance status?

**Winner Selection:**
- Highest total score
- Must score >= 8/10 on VPS Resource Fit
- Must score >= 8/10 on Reliability (financial criticality)
- Must score >= 7/10 on Monitoring

---

**END OF MISSION ANALYSIS**

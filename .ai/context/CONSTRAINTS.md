# PROJECT CONSTRAINTS

**Project:** Unified Business Management System
**Version:** 0.1.0
**Last Updated:** 2026-01-28

---

## HARD CONSTRAINTS (Cannot Be Violated)

### Budget Constraints

**Total Development Budget: $15,000 USD**
- Maximum budget for entire project
- Includes all development, testing, deployment
- Does NOT include ongoing operational costs
- Status: LOCKED (DEC-007)

**Monthly Operational Cost: $200/month maximum**
- VPS hosting
- API costs (M-Pesa, SMS if used)
- Domain name, SSL certificates
- Backup storage
- Monitoring tools
- Status: LOCKED (DEC-007)

**Implications:**
- Must use open-source technologies
- VPS hosting only (no AWS/GCP/Azure unpredictable costs)
- Minimal third-party API dependencies
- Cost-effective monitoring solutions

---

### Timeline Constraints

**MVP Delivery: 3 months (by 2026-04-28)**
- Sprint 1-2 (Weeks 1-4): Foundation + Financial Core
- Sprint 3-4 (Weeks 5-8): Water Business + M-Pesa
- Sprint 5-6 (Weeks 9-12): Laundry + Retail + BI + Deployment
- Status: LOCKED (DEC-007)

**Phased Rollout:**
1. Water Business (Sprint 3-4)
2. Laundry Business (Sprint 5-6)
3. Retail Business (Sprint 5-6)

**Implications:**
- Cannot delay decisions (blocks implementation)
- Parallel work where possible
- MVP prioritization critical
- Deferral of non-essential features to Phase 2

---

### Technology Constraints

**MUST Use:**
- Django 5.0+ (latest stable) - LOCKED (DEC-002)
- PostgreSQL 15+ - LOCKED (DEC-002)
- Progressive Web App (PWA) - LOCKED (DEC-002)
- Docker deployment - LOCKED (DEC-002)

**CANNOT Use:**
- Expensive proprietary tools (exceeds budget)
- Cloud services with unpredictable costs (AWS/GCP/Azure)
- Frameworks requiring credit card payment
- Native mobile apps (exceeds budget/timeline)

**Implications:**
- Limited to Python/Django ecosystem
- Open-source database (PostgreSQL)
- No commercial BI tools
- No enterprise monitoring solutions

---

### User Constraints

**Primary User: Business Owner on Mobile Phone**
- Device: Mobile phone (Android/iOS) - 90% of operations
- Screen size: 5-7 inches (320px-428px width)
- Technical literacy: LOW
- Environment: Serving customers while recording (one-handed)
- Time pressure: < 30 seconds to record sale
- Connectivity: 4G/WiFi (unstable at times)
- Data plan: Limited
- Status: LOCKED (DEC-004)

**Implications:**
- Mobile-first UI/UX (desktop secondary)
- Touch-optimized (44px minimum targets)
- Offline capability for critical functions
- Minimal typing (select from lists)
- Fast load times (< 3 seconds on 4G)
- One-handed operation support
- Simple, intuitive interfaces
- Training time: 1 day maximum

---

### Performance Constraints

**Mobile Performance (CRITICAL):**
- Initial page load: < 3 seconds on 4G
- Subsequent navigation: < 1 second
- Sale recording: < 30 seconds total
- PWA bundle size: < 5MB
- Touch response: < 100ms
- Status: LOCKED (DEC-004)

**System Performance:**
- API response time: < 500ms
- Dashboard refresh: < 3 seconds
- Payment processing: < 2 seconds
- Support 20 concurrent mobile users
- Handle 500+ transactions per day

**Implications:**
- Code optimization mandatory
- Image compression required
- Lazy loading for reports
- Efficient API design
- Database indexing critical
- Caching strategy required

---

### Financial Constraints

**Double-Entry Accounting:**
- Every transaction must create debit + credit
- Universal ledger immutable (reversals only)
- Ledger must always balance
- Status: LOCKED (DEC-005)

**Financial Integrity:**
- Zero tolerance for calculation errors
- All money movements must be recorded
- Audit trail for 7 years (KRA compliance)
- Database transactions mandatory for financial ops

**Implications:**
- Extensive testing for financial calculations
- Transaction rollback on errors
- Audit logging for all financial actions
- Cannot delete ledger entries (reversals only)

---

### Integration Constraints

**M-Pesa Integration Required:**
- Safaricom Daraja API only
- Multiple till numbers (one per business)
- STK Push + C2B support
- Auto-reconciliation with ledger
- Status: LOCKED (DEC-006)

**Integration Complexity:**
- Must handle duplicates
- Must handle failures
- Must handle reversals
- Real-time payment callbacks
- Duplicate detection critical

**Implications:**
- Extensive API testing required
- Sandbox testing before production
- Robust error handling
- Webhook security
- Payment reconciliation logic

---

### Compliance Constraints

**Kenya Revenue Authority (KRA):**
- VAT calculations and reporting
- Tax invoice requirements
- Audit trail retention: 7 years
- Withholding tax support
- Status: LOCKED (mission requirement)

**Data Protection:**
- Data encryption at rest
- Data encryption in transit (TLS 1.3)
- Secure password storage (bcrypt)
- Audit trail for sensitive actions

**Implications:**
- Cannot use raw SQL (ORM only)
- HTTPS enforced in production
- Session security (httpOnly cookies)
- CSRF protection
- SQL injection prevention
- XSS protection

---

### Deployment Constraints

**VPS Deployment:**
- Budget: $50-100/month
- Specs: 4GB RAM, 2 CPU, 80GB SSD (to be confirmed)
- OS: Ubuntu 22.04 LTS
- Docker containers required
- Status: LOCKED (DEC-002)

**Infrastructure Limitations:**
- Single VPS (no redundancy)
- No dedicated DevOps engineer
- Owner handles basic admin tasks
- No cloud services (cost constraint)

**Implications:**
- Automated backups critical
- Disaster recovery plan required
- Simple deployment process
- Monitoring must be lightweight
- Documentation for troubleshooting

---

## SOFT CONSTRAINTS (Should Not Be Violated Without Good Reason)

### Maintainability

**Code Quality:**
- PEP 8 compliance
- Type hints (Python 3.10+)
- 80%+ test coverage
- Docstrings on all functions/classes
- Status: Target (mission requirement)

**Implications:**
- Code reviews required
- Linting (pylint, flake8)
- Type checking (mypy)
- Comprehensive test suite

---

### Scalability

**Current Scale:**
- 3 businesses
- 20 concurrent users
- 500+ transactions/day

**Future Scale (must support without code changes):**
- Add more businesses
- Add more users
- Add more payment methods
- Status: Architecture goal

**Implications:**
- Multi-tenant database design
- Proper indexing
- Efficient queries
- No hard-coded business logic

---

### Usability

**Mobile Usability:**
- Training time: 1 day per user
- Intuitive interfaces (minimal docs)
- Consistent UI/UX across businesses
- Works in bright sunlight
- No horizontal scrolling
- Status: LOCKED (DEC-004)

**Implications:**
- High contrast design
- Large touch targets
- Simple language (English/Swahili)
- Error messages in plain language
- Tutorial on first use

---

## CONSTRAINT VIOLATION PROCESS

### Requesting Constraint Exception

If a constraint must be violated:

1. **Create Escalation**
   - Identify which constraint
   - Explain why violation is necessary
   - Show impact on project (cost, timeline, scope)
   - Provide alternatives considered

2. **Human Review**
   - Business owner reviews request
   - Approves or rejects
   - If approved: Update MISSION.md, ARCHITECTURE.md

3. **Lock Decision**
   - Document in DECISIONS.md
   - Update related documentation
   - Log in AGENT_HISTORY.json

### Example Constraint Violation Request

```
Escalation: Request to Exceed $200/month Operational Cost

Constraint: Monthly operational cost limit $200/month
Reason: Need SMS notifications for low stock alerts
Impact: +$20/month (AfricasTalking API)
Alternatives: Email only (free), no notifications (risk)
Business Justification: SMS prevents stockouts, improves revenue
Request: Approval to increase monthly budget to $220/month
```

---

## CONSTRAINT SUMMARY TABLE

| Category | Constraint | Limit | Status | Can Exceed? |
|----------|------------|-------|--------|-------------|
| Budget | Total Development | $15,000 | LOCKED | No (human approval) |
| Budget | Monthly Operations | $200 | LOCKED | No (human approval) |
| Timeline | MVP Delivery | 3 months | LOCKED | No (critical) |
| Tech | Backend Framework | Django 5.0+ | LOCKED | No |
| Tech | Database | PostgreSQL 15+ | LOCKED | No |
| Tech | Frontend | PWA | LOCKED | No |
| User | Primary Device | Mobile | LOCKED | No |
| Performance | Page Load | < 3s on 4G | LOCKED | No |
| Performance | Sale Recording | < 30s | LOCKED | No |
| Financial | Accounting | Double-entry | LOCKED | No |
| Financial | Calculation Errors | 0 tolerance | LOCKED | No |
| Integration | M-Pesa | Required | LOCKED | No |
| Compliance | KRA | VAT + Audit | LOCKED | No |
| Deployment | Platform | VPS | LOCKED | No |
| Quality | Test Coverage | 80%+ | Target | Yes (with reason) |
| Quality | Code Standards | PEP 8 | Target | Yes (with reason) |

---

## CONSTRAINT INTERACTIONS

### Budget vs Timeline
- Lower budget = longer timeline (fewer developers)
- Aggressive timeline = higher cost (more developers)
- Current balance: $15,000 / 3 months

### Mobile vs Feature Richness
- Mobile constraint = feature simplicity
- Complex features = harder on mobile
- Balance: MVP focuses on core features only

### Performance vs Offline
- Fast performance = minimal code
- Offline = additional code (service workers)
- Balance: Lazy loading, efficient caching

### Cost vs Quality
- Low cost = open-source tools
- High quality = extensive testing
- Balance: Open-source + comprehensive testing

---

**END OF CONSTRAINTS DOCUMENT**

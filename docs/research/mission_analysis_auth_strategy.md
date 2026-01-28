# Mission Analysis: API Authentication Strategy

**Project:** Unified Business Management System
**Research Date:** 2026-01-28
**Research Topic:** API Authentication Strategy for Django 5.0+ REST API serving React 18 Mobile PWA

---

## Mission Requirements Analysis

### Core Goal
Build a production-grade, unified enterprise management system enabling one business owner to efficiently operate three distinct businesses (Water Packaging, Laundry, Retail/LPG) from a single mobile PWA.

### Critical Success Factors

**Operational Requirements:**
- Owner records sales in < 30 seconds on mobile (while serving customers)
- Primary user: Business owner on mobile phone (90% of operations)
- 1 primary user (owner) + optional accountant + future staff
- Session timeout: 2 hours (mobile context)
- PIN option for quick login (4-6 digits)

**Security Requirements:**
- Financial transactions (zero tolerance for fraud)
- Mobile device loss/theft scenario protection
- Token theft protection
- HTTPS enforced (TLS 1.3)
- Rate limiting on login (5 attempts/minute)
- Audit trail for all sensitive actions

**Mobile-First Constraints:**
- Offline capability for critical functions
- Works on 5-inch mobile screen (320px - 428px)
- Intuitive for non-technical user
- Training time: 1 day maximum
- Touch-optimized interface
- Limited mobile data plan

**Technical Stack:**
- Backend: Django 5.0+ with Django REST Framework (DRF)
- Frontend: React 18 + Mantine UI (mobile PWA)
- Offline Storage: Dexie.js (IndexedDB wrapper) - DEC-P03
- Task Queue: Django-RQ (pending decision)
- Caching: Redis + PWA Service Worker (pending decision)

### Authentication-Specific Requirements

**From MISSION.md (Lines 338-340):**
- Password policy: min 8 chars
- Session timeout: 2 hours of inactivity (mobile context)
- PIN option for quick mobile login (4-6 digits)

**From ARCHITECTURE.md (Lines 170-177):**
- Mobile app security
- Session timeout handling (2-hour mobile requirement)
- PIN-based quick login feasibility
- Token refresh strategy

**From CONSTRAINTS.md (Lines 530-541):**
- HTTPS enforced
- Session management (secure, httpOnly cookies)
- Rate limiting on login (5 attempts/minute)
- CSRF protection
- XSS protection
- Audit trail for all sensitive actions

### Budget & Timeline Constraints
- Total Budget: $15,000 USD
- Monthly Operations: $200/month maximum
- MVP Timeline: 3 months (by 2026-04-28)
- Implementation time available: 1-2 weeks for authentication system

---

## Authentication Requirements Breakdown

### 1. Mobile-First Authentication
**Requirements:**
- Fast on mobile (login in < 10 seconds)
- Works offline (token storage in Dexie.js)
- PIN-based quick login (4-6 digits) for convenience
- Touch-optimized login interface
- One-handed operation support

**Impact on Authentication Choice:**
- Must support token refresh without requiring full re-login
- Must handle intermittent connectivity gracefully
- Token storage must work with Dexie.js (IndexedDB)
- Quick PIN re-authentication after session timeout

### 2. Security Requirements
**Financial Data Protection:**
- Zero tolerance for fraud
- Financial transactions require strong authentication
- Audit trail for all authenticated actions
- Protection against token theft and replay attacks

**Device Loss/Theft Protection:**
- Remote logout capability (token revocation)
- Session timeout after 2 hours inactivity
- Biometric authentication support (future)
- Device binding (optional, enhances security)

**Attack Prevention:**
- Rate limiting on login (5 attempts/minute)
- Brute force protection
- CSRF protection
- XSS protection
- SQL injection prevention (ORM only)

### 3. Session Management
**2-Hour Mobile Session Timeout:**
- Access token lifetime: ~15-30 minutes (best practice)
- Refresh token lifetime: ~7-30 days (convenience)
- Inactivity timeout: 2 hours maximum
- Automatic token refresh before expiration

**PIN-Based Quick Login:**
- PIN (4-6 digits) for convenience after initial authentication
- PIN stored securely on device (encrypted)
- PIN authentication reduces friction for frequent access
- PIN can be enabled/disabled per user preference

### 4. PWA Compatibility
**Service Worker Integration:**
- Authentication state must be accessible to Service Worker
- Token refresh must work offline-first
- Queued API requests execute when connection restores
- Background sync for token refresh

**Offline Token Storage:**
- Dexie.js (IndexedDB) for offline token persistence
- Secure token storage strategy (XSS protection)
- Token encryption at rest (defense in depth)
- Survives browser crashes and device restarts

### 5. Django Integration
**Django REST Framework (DRF) Support:**
- Must integrate seamlessly with DRF permissions
- Support Django's built-in User model (or compatible)
- Django admin integration (for owner management)
- DRF throttling and rate limiting integration

**Multi-Business Support:**
- User can access all 3 businesses with one login
- Role-based permissions (Owner: all, Accountant: finance only)
- Audit trail per business context

---

## Evaluation Criteria for Authentication Options

### 1. Security (Weight: 35%)
- Token security (theft protection, replay protection)
- Device theft handling (remote logout, token revocation)
- Compliance with financial data requirements
- Attack prevention (XSS, CSRF, brute force)

### 2. Mobile Performance (Weight: 25%)
- Token size (affects mobile data usage)
- Authentication overhead (API response time)
- Login speed (< 10 seconds target)
- Token refresh efficiency

### 3. Offline Support (Weight: 20%)
- Dexie.js compatibility
- Offline token refresh capability
- Service Worker integration
- Queue-and-replay support

### 4. Django Integration (Weight: 15%)
- DRF support (native or via packages)
- Django admin compatibility
- Permission system integration
- Community support and documentation

### 5. Complexity (Weight: 5%)
- Learning curve for Django developers
- Implementation time (fits 1-2 week timeline)
- Maintenance overhead
- Debugging and testing complexity

---

## User Flow Analysis

### Primary Flow: Business Owner (90% Usage)

**Initial Login (Once per session):**
1. Owner opens PWA on mobile phone
2. Enters username + password (or PIN if enabled)
3. System authenticates and returns access + refresh tokens
4. Tokens stored securely in Dexie.js (IndexedDB)
5. Access token used in API Authorization header

**Subsequent Access (Frequent):**
1. Owner opens PWA (already authenticated)
2. Access token in memory (from Dexie.js)
3. If access token expired, automatic refresh using refresh token
4. No user intervention required (silent refresh)

**Session Timeout (After 2 hours inactivity):**
1. Owner returns to app after > 2 hours
2. Access token expired, refresh token may be expired
3. Prompt for PIN quick login (if enabled)
4. Re-authenticate with PIN, receive fresh tokens
5. Continue working

**Device Loss/Theft:**
1. Owner reports device lost
2. Admin revokes all tokens for user (from another device)
3. Stolen device cannot access API (tokens invalid)
4. Owner sets up new device with fresh credentials

### Secondary Flow: Accountant (Optional, Future)

**Login (Daily):**
1. Accountant opens PWA on device
2. Enters username + password
3. Limited permissions (finance only, no operations)

**Usage:**
- View financial reports
- Record expenses
- Reconcile accounts
- Cannot modify sales or inventory

---

## Technical Constraints Impact

### Constraint 1: Dexie.js for Offline Storage (DEC-P03)
**Impact:**
- Refresh tokens MUST be stored in IndexedDB (via Dexie.js)
- Access tokens can be in-memory (React state) for security
- Token refresh logic must work with Dexie.js API
- Must handle IndexedDB quota limits (~500MB)

**Security Consideration:**
- IndexedDB is JavaScript-accessible (XSS vulnerability)
- Defense in depth: httpOnly cookies for refresh tokens (more secure)
- Alternative: Encrypted tokens in IndexedDB (additional layer)

### Constraint 2: React 18 + Mantine UI (DEC-P01, DEC-P02)
**Impact:**
- React Context API for authentication state management
- Mantine UI components for login forms (mobile-optimized)
- React hooks for token refresh logic
- Integration with Dexie.js (dexie-react-hooks)

### Constraint 3: Django 5.0+ with DRF
**Impact:**
- Must use DRF authentication classes or compatible package
- Django's built-in User model or custom user model
- DRF permissions for role-based access
- Integration with Django admin (user management)

### Constraint 4: 3-Month MVP Timeline
**Impact:**
- Implementation time: 1-2 weeks maximum
- Cannot use overly complex solutions (OAuth2 provider)
- Must use well-documented, proven libraries
- Minimal custom code (prefer battle-tested packages)

### Constraint 5: $15,000 Budget + $200/month Ops
**Impact:**
- No third-party authentication services (Auth0, Firebase Auth)
- Open-source authentication packages only
- No additional infrastructure costs (authentication runs on existing VPS)

---

## Security Risk Analysis

### Risk 1: XSS Attack (Token Theft from IndexedDB)
**Probability:** Medium
**Impact:** High (financial data access)
**Mitigation:**
- Short-lived access tokens (15-30 minutes)
- httpOnly cookies for refresh tokens (preferred)
- Content Security Policy (CSP) headers
- Input validation and sanitization
- Regular security audits

### Risk 2: Token Replay Attack
**Probability:** Low
**Impact:** High (fraudulent transactions)
**Mitigation:**
- JWT jti (JWT ID) claim for unique token identifiers
- Token blacklist on logout/revocation
- Refresh token rotation (one-time use)
- Short access token lifetime

### Risk 3: Device Theft
**Probability:** Medium
**Impact:** Critical (full system access)
**Mitigation:**
- Remote logout capability (token revocation endpoint)
- Short session timeout (2 hours)
- Biometric authentication (future enhancement)
- Device binding (optional)

### Risk 4: Brute Force Password Attack
**Probability:** High (automated bots)
**Impact:** Medium (account compromise)
**Mitigation:**
- Rate limiting (5 attempts/minute) - already in constraints
- Account lockout after N failed attempts
- Email notifications for suspicious activity
- Strong password policy (min 8 chars)

### Risk 5: Man-in-the-Middle Attack
**Probability:** Low
**Impact:** High (token interception)
**Mitigation:**
- HTTPS enforced (TLS 1.3) - already in constraints
- Certificate pinning (optional, mobile apps)
- Secure cookie flags (httpOnly, Secure, SameSite)

---

## Success Metrics for Authentication Choice

### Functional Metrics
- [ ] Login works in < 10 seconds on 4G mobile
- [ ] Token refresh happens automatically (silent)
- [ ] PIN-based quick login functional (4-6 digits)
- [ ] Session timeout enforced (2 hours inactivity)
- [ ] Remote logout works (device loss scenario)
- [ ] Offline token storage via Dexie.js functional
- [ ] Works with Service Worker (background refresh)

### Security Metrics
- [ ] Zero unauthorized access incidents
- [ ] All tokens stored securely (httpOnly cookies preferred)
- [ ] Token revocation works (logout, device loss)
- [ ] Rate limiting enforced (5 login attempts/minute)
- [ ] Audit trail captures all authentication events
- [ ] Passes security audit (before production)

### Performance Metrics
- [ ] Access token size < 1KB (minimizes mobile data)
- [ ] Authentication adds < 50ms to API response time
- [ ] Token refresh adds < 200ms overhead
- [ ] PWA bundle increase < 50KB (auth libraries)

### Usability Metrics
- [ ] Training time < 1 hour for authentication flows
- [ ] Owner can login in < 5 steps
- [ ] PIN login takes < 3 seconds
- [ ] Clear error messages (plain English/Swahili)
- [ ] Touch targets min 44px (mobile optimization)

### Development Metrics
- [ ] Implementation time: 1-2 weeks
- [ ] Well-documented libraries (active maintenance)
- [ ] Django developer learning curve < 3 days
- [ ] Integrates with existing stack (Django 5, DRF, React 18)
- [ ] Test coverage > 80% for auth code

---

## Integration Points

### With Dexie.js (Offline Storage - DEC-P03)
**Schema Requirements:**
```javascript
// Dexie.js schema for authentication
db.version(1).stores({
  auth_tokens: '++id, userId, access_token, refresh_token, expires_at',
  auth_state: 'userId, is_authenticated, last_activity'
});
```

**Operations:**
- Store access + refresh tokens after successful login
- Retrieve tokens on app load (from IndexedDB)
- Clear tokens on logout
- Update last_activity timestamp (for 2-hour timeout)

### With Django-RQ (Task Queue - Pending)
**Background Tasks:**
- Send email notifications for login from new device
- Purge expired blacklisted tokens (cleanup job)
- Audit log aggregation and reporting

### With Redis + Service Worker (Caching - Pending)
**Cached Data:**
- User permissions (cached in Redis, 5-minute TTL)
- Authentication state (Service Worker cache)
- Token blacklist (Redis set, fast lookup)

### With React 18 + Mantine UI
**Components Required:**
- LoginForm (username/password)
- PinForm (4-6 digit PIN entry)
- AuthProvider (React Context for auth state)
- ProtectedRoute (route guard for authenticated pages)
- TokenRefreshHook (automatic token refresh)

---

## Open Questions for Research

1. **JWT vs DRF Token Auth:** Which provides better security and mobile performance for PWA?

2. **Token Storage Strategy:** httpOnly cookies vs IndexedDB (via Dexie.js) for refresh tokens?

3. **PIN Authentication Security:** How to implement PIN-based quick login securely (not trivial password)?

4. **Token Refresh Strategy:** How to handle token refresh offline (when network unavailable)?

5. **Token Revocation:** How to implement remote logout (device loss) with stateless JWT?

6. **Django Package Selection:** Which Django 5-compatible package provides best JWT implementation?

7. **Mantine UI Integration:** Which Mantine components best support mobile authentication flows?

8. **Service Worker Auth:** How Service Workers handle authenticated API requests (token injection)?

---

## Mission Alignment Score

Each authentication option will be scored against these mission requirements:

| Requirement | Weight | Why Critical |
|-------------|--------|--------------|
| Mobile Performance | 25% | Owner uses mobile 90%, < 30 sec sale recording |
| Security | 35% | Financial data, zero fraud tolerance |
| Offline Support | 20% | Dexie.js selected, zero data loss requirement |
| Django Integration | 15% | Django 5+ required, DRF standard |
| Complexity | 5% | 3-month timeline, 1-2 week implementation |

**Maximum Score:** 10 points per criterion
**Weighted Score:** Requirement Weight × Criterion Score
**Total Score:** Sum of Weighted Scores (max 10)

---

## Conclusion

This analysis defines the authentication requirements based on mission constraints:

**Non-Negotiable Requirements:**
- Financial-grade security (zero fraud tolerance)
- Mobile-first UX (login < 10 seconds, PIN quick login)
- Offline capability (Dexie.js integration)
- 2-hour session timeout
- Remote logout (device theft protection)
- Django 5.0 + DRF integration
- React 18 + Mantine UI compatibility
- 1-2 week implementation timeline

**Primary Decision Factors:**
1. Security (35% weight) - Financial data protection
2. Mobile Performance (25% weight) - User experience
3. Offline Support (20% weight) - Dexie.js + PWA
4. Django Integration (15% weight) - Stack compatibility
5. Complexity (5% weight) - Timeline constraint

**Next Steps:**
Research authentication options and score against these criteria to recommend optimal strategy.

---

**END OF MISSION ANALYSIS**

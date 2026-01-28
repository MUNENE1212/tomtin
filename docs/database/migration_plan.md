# Database Migration Plan - Multi-Business ERP System

**Last Updated:** 2026-01-28
**Status:** Ready for Implementation
**Django Version:** 5.0+
**PostgreSQL Version:** 15+

---

## Table of Contents

1. [Pre-Migration Checklist](#pre-migration-checklist)
2. [Migration Phases](#migration-phases)
3. [Step-by-Step Migration](#step-by-step-migration)
4. [Rollback Strategy](#rollback-strategy)
5. [Post-Migration Tasks](#post-migration-tasks)
6. [Monitoring & Validation](#monitoring--validation)

---

## Pre-Migration Checklist

### Environment Setup

- [ ] PostgreSQL 15+ installed and running
- [ ] Python 3.10+ installed
- [ ] Django 5.0+ installed in virtual environment
- [ ] Database user created with necessary privileges
- [ ] Database backup strategy configured
- [ ] Migration environment (development/staging) ready

### Backup Strategy

**Before any migration:**

```bash
# 1. Backup existing database (if any)
pg_dump -U postgres -d tomtin_erp > backup_before_migration_$(date +%Y%m%d).sql

# 2. Compress backup
gzip backup_before_migration_$(date +%Y%m%d).sql

# 3. Store backup securely (off-site if production)
```

### Access Configuration

```python
# settings.py - Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'tomtin_erp',
        'USER': 'tomtin_user',
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'prefer',
            'connect_timeout': 10,
        },
        'CONN_MAX_AGE': 600,
    }
}
```

---

## Migration Phases

### Phase 1: Foundation (Week 1)

**Objective:** Set up Django project and core infrastructure

**Tasks:**
1. Create Django project structure
2. Set up PostgreSQL database
3. Create core Django apps
4. Configure Django settings
5. Set up Git repository

**Deliverables:**
- Django project skeleton
- Database connection working
- Apps: `core`, `financial`, `water`, `laundry`, `retail`
- Git repository initialized

### Phase 2: User & Business Management (Week 2)

**Objective:** Implement user authentication and business configuration

**Tasks:**
1. Create User model (extends AbstractUser)
2. Create Business, BusinessSettings, MPesaTill models
3. Create Role and BusinessAccess models
4. Implement authentication views
5. Set up admin interface

**Deliverables:**
- User authentication working
- Business entities created
- Admin panel configured
- User can log in and view businesses

### Phase 3: Financial Core (Week 3-4)

**Objective:** Implement double-entry bookkeeping system

**Tasks:**
1. Create AccountType and Account models
2. Create TransactionType model
3. Create JournalEntry and JournalEntryLine models
4. Create Ledger model (immutable)
5. Create AccountBalance and Reconciliation models
6. Implement double-entry validation
7. Create database triggers for balance updates
8. Test financial integrity

**Deliverables:**
- Chart of accounts seeded
- Journal entry creation working
- Double-entry validation enforced
- Ledger entries immutable
- Account balances auto-update

### Phase 4: Water Business Module (Week 5)

**Objective:** Implement water packaging business logic

**Tasks:**
1. Create WaterProductSize model
2. Create WaterInventory model
3. Create WaterProduction model
4. Create WaterSale model
5. Integrate with financial core (auto-create journal entries)
6. Implement inventory updates
7. Test production and sale flows

**Deliverables:**
- Water inventory tracking
- Production recording
- Sale recording with payment
- Financial integration working

### Phase 5: Laundry Business Module (Week 6)

**Objective:** Implement laundry business logic

**Tasks:**
1. Create LaundryCustomer model (extends Customer)
2. Create LaundryServiceType model
3. Create LaundryJob model
4. Create LaundryJobItem model
5. Implement job status workflow
6. Integrate with financial core
7. Test job creation and payment flows

**Deliverables:**
- Laundry job tracking
- Job status workflow
- Payment recording
- Customer balance tracking

### Phase 6: Retail Business Module (Week 7)

**Objective:** Implement retail and LPG business logic

**Tasks:**
1. Create RetailProductCategory model
2. Create RetailProduct model
3. Create RetailInventory model
4. Create RetailLPGCylinder model
5. Create RetailLPGExchange model
6. Create RetailSale and RetailSaleItem models
7. Integrate with financial core
8. Test retail and LPG flows

**Deliverables:**
- Retail product catalog
- Inventory tracking
- LPG cylinder tracking
- Cylinder exchange tracking
- Sale recording

### Phase 7: Audit & Compliance (Week 8)

**Objective:** Implement audit logging and compliance features

**Tasks:**
1. Create AuditLog model
2. Implement Django signals for audit logging
3. Set up 7-year retention policy
4. Implement data encryption at rest
5. Configure backup automation
6. Test audit trail

**Deliverables:**
- All changes logged
- Audit log queries working
- Backup automation configured
- Encryption enabled

### Phase 8: Testing & Optimization (Week 9)

**Objective:** Comprehensive testing and performance optimization

**Tasks:**
1. Write unit tests for all models
2. Write integration tests for business logic
3. Test double-entry integrity
4. Performance testing (500+ transactions/day)
5. Index optimization
6. Query optimization
7. Load testing

**Deliverables:**
- 80%+ test coverage
- All tests passing
- Performance targets met
- API response < 500ms

---

## Step-by-Step Migration

### Step 1: Create Django Project

```bash
# 1. Create project directory
mkdir tomtin && cd tomtin

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install django==5.0.1
pip install psycopg2-binary
pip install python-decouple
pip freeze > requirements.txt

# 4. Create Django project
django-admin startproject config .

# 5. Create Django apps
python manage.py startapp core
python manage.py startapp financial
python manage.py startapp water
python manage.py startapp laundry
python manage.py startapp retail
```

### Step 2: Configure Django Settings

```python
# config/settings.py

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Local apps
    'core',
    'financial',
    'water',
    'laundry',
    'retail',
]

# Custom user model
AUTH_USER_MODEL = 'core.User'

# Database configuration (see Pre-Migration Checklist)

# Security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
CSRF_COOKIE_SECURE = True  # In production
SESSION_COOKIE_SECURE = True  # In production
```

### Step 3: Copy Models to Apps

```bash
# Copy models from documentation to apps
cp docs/database/django_models.py core/models.py
# Extract core models and keep in core/models.py
# Extract financial models and put in financial/models.py
# Extract water models and put in water/models.py
# Extract laundry models and put in laundry/models.py
# Extract retail models and put in retail/models.py
```

### Step 4: Create Migrations

```bash
# For each app, create migrations
python manage.py makemigrations core
python manage.py makemigrations financial
python manage.py makemigrations water
python manage.py makemigrations laundry
python manage.py makemigrations retail

# Review migrations
python manage.py showmigrations

# Apply migrations
python manage.py migrate

# Expected output:
# Running migrations:
#   core, 0001_initial
#   financial, 0001_initial
#   water, 0001_initial
#   laundry, 0001_initial
#   retail, 0001_initial
```

### Step 5: Load Seed Data

```bash
# Option 1: Use Django seed data (recommended)
python manage.py loaddata seed_data.json

# Option 2: Use SQL seed data
psql -U tomtin_user -d tomtin_erp -f docs/database/seed_data.sql

# Verify seed data
python manage.py shell
>>> from core.models import Business
>>> Business.objects.count()
3
>>> from financial.models import Account
>>> Account.objects.count()
30
```

### Step 6: Create Superuser

```bash
python manage.py createsuperuser

# Enter details:
# Email: owner@tomtin.com
# First name: Business
# Last name: Owner
# Phone number: +254700000000
# Password: [secure password]
```

### Step 7: Register Models in Admin

```python
# core/admin.py
from django.contrib import admin
from .models import User, Role, BusinessAccess, Business, BusinessSettings, MPesaTill

admin.site.register(User)
admin.site.register(Role)
admin.site.register(BusinessAccess)
admin.site.register(Business)
admin.site.register(BusinessSettings)
admin.site.register(MPesaTill)

# Repeat for other apps...
```

### Step 8: Test Admin Interface

```bash
# Run development server
python manage.py runserver

# Visit admin: http://localhost:8000/admin
# Log in with superuser credentials
# Verify:
# - Can see all businesses
# - Can see chart of accounts
# - Can create test journal entry
# - Double-entry validation works
```

---

## Rollback Strategy

### Development Environment

```bash
# Rollback one migration
python manage.py migrate financial zero

# Rollback all migrations
python manage.py migrate zero

# Re-apply migrations
python manage.py migrate

# Reset database (CAUTION: Deletes all data)
dropdb tomtin_erp
createdb tomtin_erp
python manage.py migrate
python manage.py loaddata seed_data.json
```

### Production Environment

**NEVER rollback migrations in production with live data!**

Instead:
1. Create new migration to fix issues
2. Use transactions for data integrity
3. Test rollback strategy in staging first

**Emergency rollback (if absolutely necessary):**

```bash
# 1. Stop application
sudo systemctl stop gunicorn

# 2. Restore from backup
psql -U postgres tomtin_erp < backup_before_migration_YYYYMMDD.sql

# 3. Verify data integrity
python manage.py check
python manage.py test

# 4. Restart application
sudo systemctl start gunicorn
```

---

## Post-Migration Tasks

### Task 1: Configure Backups

```bash
# Create backup script
nano /usr/local/bin/backup_tomtin.sh

#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="//backups"
pg_dump -U postgres tomtin_erp | gzip > $BACKUP_DIR/tomtin_backup_$DATE.sql.gz

# Keep last 7 days
find $BACKUP_DIR -name "tomtin_backup_*.sql.gz" -mtime +7 -delete

# Make executable
chmod +x /usr/local/bin/backup_tomtin.sh

# Add to crontab (daily at 2 AM)
crontab -e
0 2 * * * /usr/local/bin/backup_tomtin.sh
```

### Task 2: Set Up Monitoring

```bash
# Install monitoring tools
pip install django-prometheus
pip install sentry-sdk

# Add to INSTALLED_APPS
INSTALLED_APPS += ['django_prometheus']

# Add to URLs
urlpatterns = [
    path('metrics/', include('django_prometheus.urls')),
]

# Configure Prometheus to scrape metrics
```

### Task 3: Configure Connection Pooling

```bash
# Install PgBouncer
sudo apt-get install pgbouncer

# Configure PgBouncer
sudo nano /etc/pgbouncer/pgbouncer.ini

[databases]
tomtin_erp = host=localhost port=5432 dbname=tomtin_erp

[pgbouncer]
pool_mode = transaction
max_client_conn = 100
default_pool_size = 20
reserve_pool_size = 5
reserve_pool_timeout = 3

# Restart PgBouncer
sudo systemctl restart pgbouncer
```

### Task 4: Performance Testing

```bash
# Load test with Apache Bench
ab -n 1000 -c 10 http://localhost:8000/api/v1/dashboard/

# Expected results:
# - 1000 requests, 10 concurrent
# - 0 failed requests
# - Average response time < 500ms
# - 95th percentile < 800ms
```

### Task 5: Security Hardening

```bash
# Enable SSL (Let's Encrypt)
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d tomtin.example.com

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Enable PostgreSQL encryption
# sudo nano /etc/postgresql/15/main/postgresql.conf
# ssl = on
# ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
# ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
```

---

## Monitoring & Validation

### Health Checks

```python
# Create health check endpoint
# api/views.py

from django.db import connections
from django.http import JsonResponse

def health_check(request):
    checks = {
        'database': 'unknown',
        'redis': 'unknown',
    }

    # Check database
    try:
        db_conn = connections['default']
        db_conn.cursor()
        checks['database'] = 'healthy'
    except Exception as e:
        checks['database'] = f'unhealthy: {str(e)}'

    # Check Redis (if configured)
    try:
        import redis
        r = redis.Redis(host='localhost', port=6379)
        r.ping()
        checks['redis'] = 'healthy'
    except Exception as e:
        checks['redis'] = f'unhealthy: {str(e)}'

    status_code = 200 if all(v == 'healthy' for v in checks.values()) else 503
    return JsonResponse(checks, status=status_code)
```

### Performance Metrics

**Key metrics to monitor:**

1. **Database Connection Pool**
   - Active connections
   - Idle connections
   - Connection wait time

2. **Query Performance**
   - Slow query log (> 1 second)
   - Index usage ratio
   - Sequential scans

3. **API Response Times**
   - P50: < 300ms
   - P95: < 500ms
   - P99: < 800ms

4. **Transaction Integrity**
   - Journal entries balance
   - Ledger entries immutable
   - Account balances accurate

### Validation Queries

```sql
-- Validate journal entries balance
SELECT
    je.id,
    je.entry_number,
    je.total_debit,
    je.total_credit,
    CASE WHEN je.total_debit != je.total_credit THEN 'UNBALANCED' ELSE 'OK' END AS status
FROM journal_entry je
WHERE je.status = 'posted'
  AND je.total_debit != je.total_credit;

-- Should return 0 rows

-- Validate ledger immutability (no deleted entries)
SELECT COUNT(*) AS deleted_ledger_entries
FROM ledger
WHERE created_at < NOW() - INTERVAL '1 day'
  AND id NOT IN (
    SELECT MAX(id) FROM ledger GROUP BY account_id, business_id, transaction_date
  );

-- Should show no unexpected deletions

-- Check account balances accuracy
SELECT
    a.account_number,
    a.name,
    a.current_balance AS stored_balance,
    COALESCE(
        (SELECT balance_after
         FROM ledger
         WHERE ledger.account_id = a.id
         ORDER BY transaction_date DESC, id DESC
         LIMIT 1),
        0
    ) AS calculated_balance,
    CASE
        WHEN a.current_balance = COALESCE(
            (SELECT balance_after
             FROM ledger
             WHERE ledger.account_id = a.id
             ORDER BY transaction_date DESC, id DESC
             LIMIT 1),
            0
        ) THEN 'OK'
        ELSE 'MISMATCH'
    END AS status
FROM account a
WHERE a.is_active = TRUE;
```

---

## Troubleshooting

### Issue: Migration Fails with "relation already exists"

**Cause:** Table already exists in database

**Solution:**
```bash
# Fake migration (mark as applied without running)
python manage.py migrate --fake

# Or drop table and re-migrate
psql -U postgres -d tomtin_erp -c "DROP TABLE IF EXISTS table_name CASCADE;"
python manage.py migrate
```

### Issue: Foreign Key Constraint Violation

**Cause:** Referenced record doesn't exist

**Solution:**
```bash
# Check referenced record exists
python manage.py shell
>>> from financial.models import Account
>>> Account.objects.filter(id=1).exists()

# If False, create the record or fix the foreign key reference
```

### Issue: Double-Entry Validation Fails

**Cause:** Journal entry lines don't balance

**Solution:**
```python
# Check journal entry
je = JournalEntry.objects.get(entry_number='JE-20260128-0001')
total_debit = je.lines.filter(is_debit=True).aggregate(Sum('amount'))['amount__sum']
total_credit = je.lines.filter(is_debit=False).aggregate(Sum('amount'))['amount__sum']
print(f"Debit: {total_debit}, Credit: {total_credit}")

# If they don't match, add balancing entry
JournalEntryLine.objects.create(
    journal_entry=je,
    account=Account.objects.get(account_number='1170'),  # Cash account
    description='Balancing entry',
    is_debit=True if total_debit < total_credit else False,
    amount=abs(total_debit - total_credit)
)
```

---

## Migration Checklist

- [ ] Development environment set up
- [ ] PostgreSQL database created
- [ ] Django project created
- [ ] Django apps created
- [ ] Models copied to apps
- [ ] Migrations created
- [ ] Migrations applied successfully
- [ ] Seed data loaded
- [ ] Superuser created
- [ ] Admin interface working
- [ ] Can log in and view businesses
- [ ] Chart of accounts visible
- [ ] Test journal entry created
- [ ] Double-entry validation working
- [ ] Account balances updating
- [ ] All apps tested (water, laundry, retail)
- [ ] Unit tests written
- [ ] Integration tests passing
- [ ] Performance targets met
- [ ] Backups configured
- [ ] Monitoring configured
- [ ] Documentation complete
- [ ] Ready for production deployment

---

## Next Steps

1. **Proceed to Production Migration** (when all checkboxes complete)
2. **Implement Signal Handlers** (for audit logging and financial integration)
3. **Create API Endpoints** (for mobile PWA)
4. **Implement Caching** (Redis)
5. **Set Up CI/CD Pipeline**
6. **Deploy to Production**

---

**Document Version:** 1.0
**Last Updated:** 2026-01-28
**Status:** Ready for Implementation

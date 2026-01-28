"""
Django Models - Multi-Business ERP System
Database: PostgreSQL 15+
Django: 5.0+

This file contains all Django models for the multi-business ERP system.
Models are organized by domain/app.

LAST UPDATED: 2026-01-28
"""

from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
import uuid


# =============================================================================
# DOMAIN 1: USER MANAGEMENT
# =============================================================================

class UserManager(BaseUserManager):
    """Custom user manager for email-based authentication."""

    def create_user(self, email, password=None, **extra_fields):
        """Create and save a regular user with the given email and password."""
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """Create and save a superuser with the given email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    """
    Extended User model for ERP system.

    Extends Django's AbstractUser with additional fields:
    - phone_number for M-Pesa integration
    - pin for quick mobile login
    - businesses (many-to-many for multi-business access)
    """

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name', 'phone_number']

    username = None  # Remove username, use email instead
    email = models.EmailField(unique=True, db_index=True)
    phone_number = models.CharField(
        max_length=20,
        unique=True,
        help_text='Phone number for M-Pesa integration and notifications'
    )
    pin = models.CharField(
        max_length=6,
        blank=True,
        null=True,
        help_text='4-6 digit PIN for quick mobile login'
    )
    date_of_birth = models.DateField(blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    is_owner = models.BooleanField(
        default=False,
        help_text='Owner has access to all businesses'
    )
    is_accountant = models.BooleanField(
        default=False,
        help_text='Accountant has read-only operations, edit finance'
    )
    businesses = models.ManyToManyField(
        'Business',
        through='BusinessAccess',
        related_name='users'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    class Meta:
        db_table = 'user'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['phone_number']),
            models.Index(fields=['is_owner', 'is_accountant']),
        ]

    def __str__(self):
        return f"{self.get_full_name()} ({self.email})"

    def has_business_access(self, business_id):
        """Check if user has access to specific business."""
        if self.is_owner or self.is_superuser:
            return True
        return self.businesses.filter(id=business_id).exists()


class Role(models.Model):
    """
    Role definition for future staff members.

    Examples: Manager, Cashier, Laundry Attendant, etc.
    Currently not used (only Owner and Accountant roles exist).
    Created for future scalability.
    """

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    permissions = models.JSONField(
        default=dict,
        help_text='JSON object defining role permissions'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'role'
        verbose_name = 'Role'
        verbose_name_plural = 'Roles'
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return self.name


class BusinessAccess(models.Model):
    """
    Many-to-many relationship between User and Business.

    Defines which user can access which business and with what permissions.
    Owner has access to all businesses (handled in has_business_access method).
    """

    PERMISSION_CHOICES = [
        ('read', 'Read Only'),
        ('write', 'Read and Write'),
        ('admin', 'Full Admin'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    business = models.ForeignKey('Business', on_delete=models.CASCADE)
    permission = models.CharField(
        max_length=20,
        choices=PERMISSION_CHOICES,
        default='read'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'business_access'
        unique_together = ['user', 'business']
        verbose_name = 'Business Access'
        verbose_name_plural = 'Business Accesses'
        indexes = [
            models.Index(fields=['user', 'business']),
            models.Index(fields=['business']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.business.name} ({self.permission})"


# =============================================================================
# DOMAIN 2: BUSINESS CONFIGURATION
# =============================================================================

class Business(models.Model):
    """
    Business entity definition.

    Represents each business: Water Packaging, Laundry, Retail/LPG.
    Can easily add more businesses in the future without schema changes.
    """

    BUSINESS_TYPE_CHOICES = [
        ('water', 'Water Packaging'),
        ('laundry', 'Laundry Services'),
        ('retail', 'Retail Shop'),
        ('other', 'Other'),
    ]

    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=200, unique=True)
    code = models.CharField(
        max_length=10,
        unique=True,
        help_text='Short code for business (e.g., WTR, LND, RTL)'
    )
    business_type = models.CharField(
        max_length=20,
        choices=BUSINESS_TYPE_CHOICES
    )
    description = models.TextField(blank=True)
    address = models.TextField(blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    is_active = models.BooleanField(default=True)
    m_pesa_till_number = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        unique=True,
        help_text='M-Pesa till number for this business'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'business'
        verbose_name = 'Business'
        verbose_name_plural = 'Businesses'
        ordering = ['name']
        indexes = [
            models.Index(fields=['code']),
            models.Index(fields=['is_active']),
            models.Index(fields=['business_type']),
        ]

    def __str__(self):
        return self.name


class BusinessSettings(models.Model):
    """
    Business-specific settings and configurations.

    Each business can have its own:
    - Tax rates
    - Currency
    - Pricing configurations
    - Operating hours
    """

    business = models.OneToOneField(
        Business,
        on_delete=models.CASCADE,
        related_name='settings'
    )
    tax_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('16.00'),
        help_text='VAT tax rate in percentage'
    )
    currency_code = models.CharField(
        max_length=3,
        default='KES',
        help_text='ISO 4217 currency code'
    )
    currency_symbol = models.CharField(max_length=5, default='KSh')
    requires_signature = models.BooleanField(
        default=False,
        help_text='Require signature on receipts above threshold'
    )
    signature_threshold = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('10000.00'),
        help_text='Amount threshold for signature requirement'
    )
    allow_negative_stock = models.BooleanField(
        default=False,
        help_text='Allow stock to go negative (not recommended)'
    )
    low_stock_threshold = models.PositiveIntegerField(
        default=10,
        help_text='Alert when stock below this quantity'
    )
    operating_hours_start = models.TimeField(default='08:00')
    operating_hours_end = models.TimeField(default='20:00')
    receipt_footer = models.TextField(
        blank=True,
        help_text='Custom footer text for receipts'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'business_settings'
        verbose_name = 'Business Settings'
        verbose_name_plural = 'Business Settings'

    def __str__(self):
        return f"Settings for {self.business.name}"


class MPesaTill(models.Model):
    """
    M-Pesa till number configuration.

    Each business can have one or more M-Pesa till numbers.
    Handles M-Pesa payment integration.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='m_pesa_tills'
    )
    till_number = models.CharField(max_length=20, unique=True)
    till_name = models.CharField(max_length=200)
    is_active = models.BooleanField(default=True)
    merchant_id = models.CharField(
        max_length=50,
        blank=True,
        help_text='Safaricom merchant ID'
    )
    consumer_key = models.CharField(
        max_length=100,
        blank=True,
        help_text='M-Pesa API consumer key (encrypted)'
    )
    consumer_secret = models.CharField(
        max_length=100,
        blank=True,
        help_text='M-Pesa API consumer secret (encrypted)'
    )
    passkey = models.CharField(
        max_length=100,
        blank=True,
        help_text='M-Pesa API passkey (encrypted)'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'm_pesa_till'
        verbose_name = 'M-Pesa Till'
        verbose_name_plural = 'M-Pesa Tills'
        unique_together = ['business', 'till_number']
        indexes = [
            models.Index(fields=['till_number']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"{self.till_name} - {self.till_number}"


# =============================================================================
# DOMAIN 3: FINANCIAL CORE (MOST CRITICAL)
# =============================================================================

class AccountType(models.Model):
    """
    Account type classification.

    Standard accounting account types:
    - Asset
    - Liability
    - Equity
    - Revenue
    - Expense
    """

    TYPE_CHOICES = [
        ('asset', 'Asset'),
        ('liability', 'Liability'),
        ('equity', 'Equity'),
        ('revenue', 'Revenue'),
        ('expense', 'Expense'),
    ]

    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(
        max_length=1,
        unique=True,
        help_text='Single letter code (A, L, E, R, X)'
    )
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    normal_balance = models.CharField(
        max_length=6,
        choices=[('debit', 'Debit'), ('credit', 'Credit')],
        help_text='Normal balance for this account type'
    )
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'account_type'
        verbose_name = 'Account Type'
        verbose_name_plural = 'Account Types'
        ordering = ['id']

    def __str__(self):
        return f"{self.name} ({self.code})"


class Account(models.Model):
    """
    Individual ledger account.

    Hierarchical structure:
    Account Type → Account Category → Account Class → Account

    Each account has a unique account number and tracks its balance.
    """

    account_number = models.CharField(max_length=10, unique=True, db_index=True)
    name = models.CharField(max_length=200, db_index=True)
    account_type = models.ForeignKey(
        AccountType,
        on_delete=models.PROTECT,
        related_name='accounts'
    )
    parent_account = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        blank=True,
        null=True,
        related_name='child_accounts',
        help_text='Parent account for hierarchical structure'
    )
    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='accounts',
        blank=True,
        null=True,
        help_text='Business-specific account (null = shared account)'
    )
    description = models.TextField(blank=True)
    current_balance = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text='Current account balance (updated by transactions)'
    )
    is_active = models.BooleanField(default=True)
    is_contra_account = models.BooleanField(
        default=False,
        help_text='Contra account has opposite normal balance'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'account'
        verbose_name = 'Account'
        verbose_name_plural = 'Accounts'
        ordering = ['account_number']
        indexes = [
            models.Index(fields=['account_number']),
            models.Index(fields=['business']),
            models.Index(fields=['account_type']),
            models.Index(fields=['parent_account']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        business_prefix = f"[{self.business.code}] " if self.business else ""
        return f"{business_prefix}{self.account_number} - {self.name}"

    def get_balance(self):
        """Get current account balance."""
        return self.current_balance

    def update_balance(self, amount, is_debit):
        """
        Update account balance based on debit/credit.

        Rules:
        - Asset/Expense accounts: Debit increases, Credit decreases
        - Liability/Equity/Revenue accounts: Credit increases, Debit decreases
        """
        normal_balance = self.account_type.normal_balance

        if self.is_contra_account:
            normal_balance = 'credit' if normal_balance == 'debit' else 'debit'

        if normal_balance == 'debit':
            # Asset/Expense: Debit increases, Credit decreases
            if is_debit:
                self.current_balance += amount
            else:
                self.current_balance -= amount
        else:
            # Liability/Equity/Revenue: Credit increases, Debit decreases
            if is_debit:
                self.current_balance -= amount
            else:
                self.current_balance += amount

        self.save(update_fields=['current_balance', 'updated_at'])


class TransactionType(models.Model):
    """
    Transaction type classification.

    Standard transaction types:
    - Sale/Service income
    - Expense
    - Deposit
    - Withdrawal
    - Transfer
    - Adjustment
    """

    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(max_length=10, unique=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'transaction_type'
        verbose_name = 'Transaction Type'
        verbose_name_plural = 'Transaction Types'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.code})"


class JournalEntry(models.Model):
    """
    Journal entry header.

    Represents a complete transaction with multiple debit/credit lines.
    Enforces double-entry bookkeeping: sum(debits) = sum(credits).
    """

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('posted', 'Posted'),
        ('reversed', 'Reversed'),
    ]

    id = models.BigAutoField(primary_key=True)
    entry_number = models.CharField(max_length=50, unique=True, db_index=True)
    business = models.ForeignKey(
        Business,
        on_delete=models.PROTECT,
        related_name='journal_entries'
    )
    transaction_type = models.ForeignKey(
        TransactionType,
        on_delete=models.PROTECT,
        related_name='journal_entries'
    )
    transaction_date = models.DateField(db_index=True)
    description = models.TextField()
    reference_number = models.CharField(
        max_length=100,
        blank=True,
        help_text='External reference (invoice number, receipt number, etc.)'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='posted'
    )
    total_debit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00')
    )
    total_credit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00')
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='journal_entries_created'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    posted_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'journal_entry'
        verbose_name = 'Journal Entry'
        verbose_name_plural = 'Journal Entries'
        ordering = ['-transaction_date', '-entry_number']
        indexes = [
            models.Index(fields=['entry_number']),
            models.Index(fields=['business', 'transaction_date']),
            models.Index(fields=['status']),
            models.Index(fields=['transaction_type']),
        ]

    def __str__(self):
        return f"JE-{self.entry_number} - {self.description[:50]}"

    def clean(self):
        """Validate that debits equal credits."""
        if self.total_debit != self.total_credit:
            raise ValidationError(
                f"Journal entry must balance. "
                f"Debits: {self.total_debit}, Credits: {self.total_credit}"
            )

    def save(self, *args, **kwargs):
        """Override save to generate entry number and validate."""
        if not self.entry_number:
            # Generate entry number: JE-YYYYMMDD-XXXX
            date_str = self.transaction_date.strftime('%Y%m%d')
            last_entry = JournalEntry.objects.filter(
                entry_number__startswith=f'JE-{date_str}'
            ).order_by('-entry_number').first()

            if last_entry:
                last_seq = int(last_entry.entry_number.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1

            self.entry_number = f'JE-{date_str}-{new_seq:04d}'

        self.full_clean()
        super().save(*args, **kwargs)


class JournalEntryLine(models.Model):
    """
    Journal entry line item.

    Each journal entry has multiple lines (debit and credit).
    Enforces double-entry bookkeeping at line level.
    """

    journal_entry = models.ForeignKey(
        JournalEntry,
        on_delete=models.CASCADE,
        related_name='lines'
    )
    account = models.ForeignKey(
        Account,
        on_delete=models.PROTECT,
        related_name='journal_entry_lines'
    )
    description = models.CharField(max_length=200)
    is_debit = models.BooleanField(
        default=True,
        help_text='True = Debit, False = Credit'
    )
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'journal_entry_line'
        verbose_name = 'Journal Entry Line'
        verbose_name_plural = 'Journal Entry Lines'
        ordering = ['journal_entry', 'id']
        indexes = [
            models.Index(fields=['journal_entry']),
            models.Index(fields=['account']),
        ]

    def __str__(self):
        dc = 'DR' if self.is_debit else 'CR'
        return f"{self.account.account_number} - {dc} {self.amount}"


class Ledger(models.Model):
    """
    Universal ledger - every money movement.

    IMMUTABLE: Ledger entries can never be deleted or modified.
    Only reversal entries can correct errors.
    This provides complete audit trail for 7 years (KRA compliance).
    """

    id = models.BigAutoField(primary_key=True)
    journal_entry = models.ForeignKey(
        JournalEntry,
        on_delete=models.PROTECT,
        related_name='ledger_entries'
    )
    journal_entry_line = models.ForeignKey(
        JournalEntryLine,
        on_delete=models.PROTECT,
        related_name='ledger_entries'
    )
    account = models.ForeignKey(
        Account,
        on_delete=models.PROTECT,
        related_name='ledger_entries'
    )
    business = models.ForeignKey(
        Business,
        on_delete=models.PROTECT,
        related_name='ledger_entries'
    )
    transaction_date = models.DateField(db_index=True)
    transaction_type = models.ForeignKey(
        TransactionType,
        on_delete=models.PROTECT
    )
    description = models.TextField()
    is_debit = models.BooleanField()
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2
    )
    balance_after = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text='Account balance after this transaction'
    )
    reference_number = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'ledger'
        verbose_name = 'Ledger Entry'
        verbose_name_plural = 'Ledger Entries'
        ordering = ['-transaction_date', '-id']
        indexes = [
            models.Index(fields=['account', 'transaction_date']),
            models.Index(fields=['business', 'transaction_date']),
            models.Index(fields=['transaction_type']),
            models.Index(fields=['reference_number']),
            models.Index(fields=['-transaction_date', 'account']),
        ]

    def __str__(self):
        dc = 'DR' if self.is_debit else 'CR'
        return f"{self.account.account_number} - {dc} {self.amount} - {self.transaction_date}"

    def delete(self, *args, **kwargs):
        """Prevent deletion of ledger entries (immutable)."""
        raise ValidationError("Ledger entries cannot be deleted. Create a reversal entry instead.")


class AccountBalance(models.Model):
    """
    Account balance snapshots.

    Periodic snapshots of account balances for performance optimization.
    Instead of calculating balances from thousands of ledger entries,
    query this table for quick balance lookups.
    """

    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='balance_snapshots'
    )
    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='account_balances'
    )
    balance_date = models.DateField(db_index=True)
    opening_balance = models.DecimalField(max_digits=15, decimal_places=2)
    closing_balance = models.DecimalField(max_digits=15, decimal_places=2)
    total_debits = models.DecimalField(max_digits=15, decimal_places=2)
    total_credits = models.DecimalField(max_digits=15, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'account_balance'
        verbose_name = 'Account Balance'
        verbose_name_plural = 'Account Balances'
        unique_together = ['account', 'business', 'balance_date']
        ordering = ['-balance_date']
        indexes = [
            models.Index(fields=['account', 'balance_date']),
            models.Index(fields=['business', 'balance_date']),
        ]

    def __str__(self):
        return f"{self.account.account_number} - {self.balance_date}: {self.closing_balance}"


class Reconciliation(models.Model):
    """
    Account reconciliation records.

    Track when accounts are reconciled (e.g., M-Pesa, bank accounts).
    Ensures system balances match external records.
    """

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('reconciled', 'Reconciled'),
        ('discrepancy', 'Discrepancy Found'),
    ]

    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name='reconciliations'
    )
    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='reconciliations'
    )
    reconciliation_date = models.DateField(db_index=True)
    system_balance = models.DecimalField(max_digits=15, decimal_places=2)
    external_balance = models.DecimalField(max_digits=15, decimal_places=2)
    difference = models.DecimalField(max_digits=15, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    notes = models.TextField(blank=True)
    reconciled_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='reconciliations'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reconciliation'
        verbose_name = 'Reconciliation'
        verbose_name_plural = 'Reconciliations'
        ordering = ['-reconciliation_date']
        indexes = [
            models.Index(fields=['account', 'reconciliation_date']),
            models.Index(fields=['business', 'reconciliation_date']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"{self.account.account_number} - {self.reconciliation_date}: {self.status}"


# =============================================================================
# DOMAIN 4: WATER PACKAGING BUSINESS
# =============================================================================

class WaterProductSize(models.Model):
    """
    Water product sizes.

    Available sizes: 500ml, 1L, 5L, 10L, etc.
    """

    name = models.CharField(max_length=50, unique=True)
    volume_ml = models.PositiveIntegerField(
        help_text='Volume in milliliters'
    )
    default_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Default selling price per unit'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'water_product_size'
        verbose_name = 'Water Product Size'
        verbose_name_plural = 'Water Product Sizes'
        ordering = ['volume_ml']

    def __str__(self):
        return f"{self.name} ({self.volume_ml}ml)"


class WaterInventory(models.Model):
    """
    Water inventory tracking.

    Tracks both empty containers and filled products.
    Each business (Water) has its own inventory.
    """

    TYPE_CHOICES = [
        ('empty', 'Empty Containers'),
        ('filled', 'Filled Products'),
    ]

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='water_inventory'
    )
    product_size = models.ForeignKey(
        WaterProductSize,
        on_delete=models.PROTECT,
        related_name='inventories'
    )
    inventory_type = models.CharField(
        max_length=10,
        choices=TYPE_CHOICES
    )
    quantity = models.PositiveIntegerField(default=0)
    unit_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text='Cost per unit (for filled products)'
    )
    selling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Selling price per unit'
    )
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'water_inventory'
        verbose_name = 'Water Inventory'
        verbose_name_plural = 'Water Inventories'
        unique_together = ['business', 'product_size', 'inventory_type']
        indexes = [
            models.Index(fields=['business', 'product_size']),
            models.Index(fields=['inventory_type']),
        ]

    def __str__(self):
        return f"{self.business.code} - {self.product_size.name} {self.inventory_type}: {self.quantity}"

    def clean(self):
        """Validate quantity doesn't go negative."""
        if self.quantity < 0:
            raise ValidationError("Quantity cannot be negative.")


class WaterProduction(models.Model):
    """
    Water production records.

    Tracks conversion of empty containers to filled products.
    Reduces empty inventory, increases filled inventory.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='water_productions'
    )
    product_size = models.ForeignKey(
        WaterProductSize,
        on_delete=models.PROTECT,
        related_name='productions'
    )
    quantity_produced = models.PositiveIntegerField(
        validators=[MinValueValidator(1)]
    )
    production_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Total cost of production'
    )
    production_date = models.DateField(db_index=True)
    notes = models.TextField(blank=True)
    recorded_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='water_productions'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'water_production'
        verbose_name = 'Water Production'
        verbose_name_plural = 'Water Productions'
        ordering = ['-production_date']
        indexes = [
            models.Index(fields=['business', 'production_date']),
            models.Index(fields=['product_size']),
        ]

    def __str__(self):
        return f"{self.business.code} - {self.product_size.name} - {self.quantity_produced} units on {self.production_date}"


class WaterSale(models.Model):
    """
    Water sales records.

    Tracks sales of filled water products to customers.
    Reduces filled inventory, records revenue.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='water_sales'
    )
    customer = models.ForeignKey(
        'Customer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='water_sales'
    )
    product_size = models.ForeignKey(
        WaterProductSize,
        on_delete=models.PROTECT,
        related_name='sales'
    )
    quantity_sold = models.PositiveIntegerField(
        validators=[MinValueValidator(1)]
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    payment_method = models.CharField(
        max_length=20,
        choices=[
            ('cash', 'Cash'),
            ('m_pesa', 'M-Pesa'),
            ('bank', 'Bank Transfer'),
        ]
    )
    m_pesa_transaction_id = models.CharField(
        max_length=100,
        blank=True,
        help_text='M-Pesa transaction reference'
    )
    sale_date = models.DateField(db_index=True)
    sale_time = models.TimeField(default=timezone.now)
    notes = models.TextField(blank=True)
    recorded_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='water_sales'
    )
    journal_entry = models.OneToOneField(
        JournalEntry,
        on_delete=models.PROTECT,
        related_name='water_sale',
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'water_sale'
        verbose_name = 'Water Sale'
        verbose_name_plural = 'Water Sales'
        ordering = ['-sale_date', '-sale_time']
        indexes = [
            models.Index(fields=['business', 'sale_date']),
            models.Index(fields=['customer']),
            models.Index(fields=['product_size']),
            models.Index(fields=['payment_method']),
        ]

    def __str__(self):
        return f"{self.business.code} - {self.quantity_sold}x {self.product_size.name} - {self.total_amount} on {self.sale_date}"

    def save(self, *args, **kwargs):
        """Calculate total amount before saving."""
        if not self.total_amount:
            self.total_amount = self.quantity_sold * self.unit_price
        super().save(*args, **kwargs)


# =============================================================================
# DOMAIN 5: LAUNDRY BUSINESS
# =============================================================================

class LaundryCustomer(models.Model):
    """
    Laundry customer profiles.

    Customers can have multiple jobs over time.
    Tracks credit limits and balances.
    """

    customer = models.OneToOneField(
        'Customer',
        on_delete=models.CASCADE,
        related_name='laundry_profile'
    )
    customer_code = models.CharField(
        max_length=20,
        unique=True,
        help_text='Unique customer code for quick lookup'
    )
    credit_limit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('5000.00'),
        help_text='Maximum credit amount'
    )
    current_balance = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text='Current outstanding balance'
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'laundry_customer'
        verbose_name = 'Laundry Customer'
        verbose_name_plural = 'Laundry Customers'
        indexes = [
            models.Index(fields=['customer_code']),
        ]

    def __str__(self):
        return f"{self.customer.name} - {self.customer_code}"

    def can_create_job(self, estimated_cost):
        """Check if customer can create job based on credit limit."""
        return (self.current_balance + estimated_cost) <= self.credit_limit


class LaundryServiceType(models.Model):
    """
    Laundry service types and pricing.

    Examples: Wash per item, Wash per kg, Dry clean, Ironing, etc.
    """

    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    pricing_type = models.CharField(
        max_length=20,
        choices=[
            ('per_item', 'Per Item'),
            ('per_kg', 'Per Kilogram'),
            ('per_bundle', 'Per Bundle'),
            ('flat_rate', 'Flat Rate'),
        ]
    )
    default_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'laundry_service_type'
        verbose_name = 'Laundry Service Type'
        verbose_name_plural = 'Laundry Service Types'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} - {self.pricing_type} @ {self.default_price}"


class LaundryJob(models.Model):
    """
    Laundry job/order.

    Represents a customer order with multiple items.
    Tracks job status through workflow.
    """

    STATUS_CHOICES = [
        ('received', 'Received'),
        ('washing', 'Washing'),
        ('drying', 'Drying'),
        ('ready', 'Ready for Pickup'),
        ('collected', 'Collected'),
        ('cancelled', 'Cancelled'),
    ]

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='laundry_jobs'
    )
    customer = models.ForeignKey(
        LaundryCustomer,
        on_delete=models.PROTECT,
        related_name='jobs'
    )
    job_number = models.CharField(
        max_length=50,
        unique=True,
        db_index=True
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='received'
    )
    received_date = models.DateField(db_index=True)
    received_time = models.TimeField(default=timezone.now)
    expected_completion_date = models.DateField(blank=True, null=True)
    actual_completion_date = models.DateField(blank=True, null=True)
    collected_date = models.DateField(blank=True, null=True)
    subtotal_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    discount_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    amount_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    balance_due = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    notes = models.TextField(blank=True)
    received_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='laundry_jobs_received'
    )
    journal_entry = models.OneToOneField(
        JournalEntry,
        on_delete=models.PROTECT,
        related_name='laundry_job',
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'laundry_job'
        verbose_name = 'Laundry Job'
        verbose_name_plural = 'Laundry Jobs'
        ordering = ['-received_date', '-job_number']
        indexes = [
            models.Index(fields=['business', 'received_date']),
            models.Index(fields=['customer']),
            models.Index(fields=['status']),
            models.Index(fields=['job_number']),
            models.Index(fields=['status', 'received_date']),
        ]

    def __str__(self):
        return f"Job {self.job_number} - {self.customer.customer.name} - {self.status}"

    def save(self, *args, **kwargs):
        """Generate job number and calculate amounts."""
        if not self.job_number:
            # Generate job number: LJ-YYYYMMDD-XXXX
            date_str = self.received_date.strftime('%Y%m%d')
            last_job = LaundryJob.objects.filter(
                job_number__startswith=f'LJ-{date_str}'
            ).order_by('-job_number').first()

            if last_job:
                last_seq = int(last_job.job_number.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1

            self.job_number = f'LJ-{date_str}-{new_seq:04d}'

        # Calculate balance due
        self.balance_due = self.total_amount - self.amount_paid

        super().save(*args, **kwargs)


class LaundryJobItem(models.Model):
    """
    Individual items in a laundry job.

    Each job can have multiple items (e.g., 5 shirts, 2 trousers, 1 bedsheet).
    """

    job = models.ForeignKey(
        LaundryJob,
        on_delete=models.CASCADE,
        related_name='items'
    )
    service_type = models.ForeignKey(
        LaundryServiceType,
        on_delete=models.PROTECT,
        related_name='job_items'
    )
    item_description = models.CharField(
        max_length=200,
        help_text='Description of item (e.g., White Shirt, Bed Sheet)'
    )
    quantity = models.PositiveIntegerField(
        validators=[MinValueValidator(1)]
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    line_total = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'laundry_job_item'
        verbose_name = 'Laundry Job Item'
        verbose_name_plural = 'Laundry Job Items'
        ordering = ['job', 'id']

    def __str__(self):
        return f"{self.quantity}x {self.item_description} - {self.line_total}"

    def save(self, *args, **kwargs):
        """Calculate line total before saving."""
        if not self.line_total:
            self.line_total = self.quantity * self.unit_price
        super().save(*args, **kwargs)


# =============================================================================
# DOMAIN 6: RETAIL/LPG BUSINESS
# =============================================================================

class RetailProductCategory(models.Model):
    """
    Retail product categories.

    Examples: Beverages, Snacks, Household, LPG, etc.
    """

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    parent_category = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        blank=True,
        null=True,
        related_name='subcategories'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'retail_product_category'
        verbose_name = 'Retail Product Category'
        verbose_name_plural = 'Retail Product Categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class RetailProduct(models.Model):
    """
    Retail product catalog.

    Includes regular retail items and LPG gas.
    """

    name = models.CharField(max_length=200, db_index=True)
    product_code = models.CharField(
        max_length=50,
        unique=True,
        help_text='Product SKU or barcode'
    )
    category = models.ForeignKey(
        RetailProductCategory,
        on_delete=models.SET_NULL,
        null=True,
        related_name='products'
    )
    description = models.TextField(blank=True)
    unit_of_measure = models.CharField(
        max_length=20,
        default='piece',
        help_text='e.g., piece, kg, litre, packet'
    )
    is_lpg = models.BooleanField(
        default=False,
        help_text='Is this an LPG gas product?'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'retail_product'
        verbose_name = 'Retail Product'
        verbose_name_plural = 'Retail Products'
        ordering = ['name']
        indexes = [
            models.Index(fields=['product_code']),
            models.Index(fields=['name']),
            models.Index(fields=['category']),
        ]

    def __str__(self):
        return f"{self.product_code} - {self.name}"


class RetailInventory(models.Model):
    """
    Retail inventory tracking.

    Tracks stock levels for each product per business.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='retail_inventory'
    )
    product = models.ForeignKey(
        RetailProduct,
        on_delete=models.PROTECT,
        related_name='inventories'
    )
    quantity_in_stock = models.PositiveIntegerField(default=0)
    buying_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Last buying price per unit'
    )
    selling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    reorder_level = models.PositiveIntegerField(
        default=10,
        help_text='Reorder when stock below this level'
    )
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'retail_inventory'
        verbose_name = 'Retail Inventory'
        verbose_name_plural = 'Retail Inventories'
        unique_together = ['business', 'product']
        indexes = [
            models.Index(fields=['business', 'product']),
            models.Index(fields=['quantity_in_stock']),
        ]

    def __str__(self):
        return f"{self.business.code} - {self.product.name}: {self.quantity_in_stock} @ {self.selling_price}"

    def is_low_stock(self):
        """Check if stock is below reorder level."""
        return self.quantity_in_stock <= self.reorder_level


class RetailLPGCylinder(models.Model):
    """
    LPG cylinder asset tracking.

    Tracks individual cylinders by brand, capacity, and serial number.
    Enables cylinder circulation tracking.

    Brands: Shell, Total, K-Gas, Africa Gas, Pro Gas, etc.
    Capacities: 6kg, 13kg, 15kg, 45kg, etc.
    """

    CYLINDER_STATUS_CHOICES = [
        ('full', 'Full'),
        ('empty', 'Empty'),
        ('customer', 'With Customer'),
        ('maintenance', 'Under Maintenance'),
    ]

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='lpg_cylinders'
    )
    brand = models.CharField(
        max_length=50,
        help_text='Cylinder brand (Shell, Total, etc.)'
    )
    capacity_kg = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        help_text='Cylinder capacity in kilograms'
    )
    serial_number = models.CharField(
        max_length=100,
        unique=True,
        db_index=True,
        help_text='Unique cylinder serial number'
    )
    status = models.CharField(
        max_length=20,
        choices=CYLINDER_STATUS_CHOICES,
        default='full'
    )
    purchase_date = models.DateField(blank=True, null=True)
    purchase_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True
    )
    last_exchange_date = models.DateField(blank=True, null=True)
    current_location = models.CharField(
        max_length=200,
        blank=True,
        help_text='Current location (shop name, customer name, etc.)'
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'retail_lpg_cylinder'
        verbose_name = 'Retail LPG Cylinder'
        verbose_name_plural = 'Retail LPG Cylinders'
        ordering = ['brand', 'capacity_kg', 'serial_number']
        indexes = [
            models.Index(fields=['serial_number']),
            models.Index(fields=['business', 'status']),
            models.Index(fields=['brand', 'capacity_kg']),
        ]

    def __str__(self):
        return f"{self.brand} {self.capacity_kg}kg - {self.serial_number} ({self.status})"


class RetailLPGExchange(models.Model):
    """
    LPG cylinder exchange records.

    Tracks full ↔ empty cylinder swaps.
    Customer brings empty cylinder, receives full cylinder.
    Price calculation: capacity_kg × price_per_kg.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='lpg_exchanges'
    )
    customer = models.ForeignKey(
        'Customer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='lpg_exchanges'
    )
    full_cylinder = models.ForeignKey(
        RetailLPGCylinder,
        on_delete=models.PROTECT,
        related_name='exchanges_as_full'
    )
    empty_cylinder = models.ForeignKey(
        RetailLPGCylinder,
        on_delete=models.PROTECT,
        related_name='exchanges_as_empty',
        blank=True,
        null=True,
        help_text='Empty cylinder returned by customer'
    )
    capacity_kg = models.DecimalField(max_digits=5, decimal_places=2)
    price_per_kg = models.DecimalField(max_digits=10, decimal_places=2)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(
        max_length=20,
        choices=[
            ('cash', 'Cash'),
            ('m_pesa', 'M-Pesa'),
            ('bank', 'Bank Transfer'),
        ]
    )
    m_pesa_transaction_id = models.CharField(max_length=100, blank=True)
    exchange_date = models.DateField(db_index=True)
    exchange_time = models.TimeField(default=timezone.now)
    notes = models.TextField(blank=True)
    recorded_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='lpg_exchanges'
    )
    journal_entry = models.OneToOneField(
        JournalEntry,
        on_delete=models.PROTECT,
        related_name='lpg_exchange',
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'retail_lpg_exchange'
        verbose_name = 'Retail LPG Exchange'
        verbose_name_plural = 'Retail LPG Exchanges'
        ordering = ['-exchange_date', '-exchange_time']
        indexes = [
            models.Index(fields=['business', 'exchange_date']),
            models.Index(fields=['customer']),
            models.Index(fields=['full_cylinder']),
        ]

    def __str__(self):
        return f"{self.full_cylinder.brand} {self.capacity_kg}kg exchange - {self.exchange_date}"

    def save(self, *args, **kwargs):
        """Calculate total amount before saving."""
        if not self.total_amount:
            self.total_amount = self.capacity_kg * self.price_per_kg
        super().save(*args, **kwargs)


class RetailSale(models.Model):
    """
    Retail sales records.

    Tracks sales of retail products (including LPG gas).
    Reduces inventory, records revenue.
    """

    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='retail_sales'
    )
    customer = models.ForeignKey(
        'Customer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='retail_sales'
    )
    sale_number = models.CharField(
        max_length=50,
        unique=True,
        db_index=True
    )
    subtotal_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    discount_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    payment_method = models.CharField(
        max_length=20,
        choices=[
            ('cash', 'Cash'),
            ('m_pesa', 'M-Pesa'),
            ('bank', 'Bank Transfer'),
            ('mixed', 'Mixed Payment'),
        ]
    )
    m_pesa_transaction_id = models.CharField(max_length=100, blank=True)
    sale_date = models.DateField(db_index=True)
    sale_time = models.TimeField(default=timezone.now)
    notes = models.TextField(blank=True)
    recorded_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='retail_sales'
    )
    journal_entry = models.OneToOneField(
        JournalEntry,
        on_delete=models.PROTECT,
        related_name='retail_sale',
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'retail_sale'
        verbose_name = 'Retail Sale'
        verbose_name_plural = 'Retail Sales'
        ordering = ['-sale_date', '-sale_number']
        indexes = [
            models.Index(fields=['business', 'sale_date']),
            models.Index(fields=['customer']),
            models.Index(fields=['payment_method']),
            models.Index(fields=['sale_number']),
        ]

    def __str__(self):
        return f"Sale {self.sale_number} - {self.total_amount} on {self.sale_date}"

    def save(self, *args, **kwargs):
        """Generate sale number before saving."""
        if not self.sale_number:
            # Generate sale number: RS-YYYYMMDD-XXXX
            date_str = self.sale_date.strftime('%Y%m%d')
            last_sale = RetailSale.objects.filter(
                sale_number__startswith=f'RS-{date_str}'
            ).order_by('-sale_number').first()

            if last_sale:
                last_seq = int(last_sale.sale_number.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1

            self.sale_number = f'RS-{date_str}-{new_seq:04d}'

        super().save(*args, **kwargs)


class RetailSaleItem(models.Model):
    """
    Individual items in a retail sale.

    Each sale can have multiple products.
    """

    sale = models.ForeignKey(
        RetailSale,
        on_delete=models.CASCADE,
        related_name='items'
    )
    product = models.ForeignKey(
        RetailProduct,
        on_delete=models.PROTECT,
        related_name='sale_items'
    )
    quantity = models.PositiveIntegerField(
        validators=[MinValueValidator(1)]
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    line_total = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'retail_sale_item'
        verbose_name = 'Retail Sale Item'
        verbose_name_plural = 'Retail Sale Items'
        ordering = ['sale', 'id']

    def __str__(self):
        return f"{self.quantity}x {self.product.name} - {self.line_total}"

    def save(self, *args, **kwargs):
        """Calculate line total before saving."""
        if not self.line_total:
            self.line_total = self.quantity * self.unit_price
        super().save(*args, **kwargs)


# =============================================================================
# DOMAIN 7: SHARED/CROSS-BUSINESS
# =============================================================================

class Customer(models.Model):
    """
    Shared customer database.

    Can be shared across all three businesses.
    Single customer profile can buy from multiple businesses.
    """

    name = models.CharField(max_length=200, db_index=True)
    phone_number = models.CharField(
        max_length=20,
        unique=True,
        db_index=True,
        help_text='Primary phone number'
    )
    phone_number_2 = models.CharField(
        max_length=20,
        blank=True,
        help_text='Secondary phone number'
    )
    email = models.EmailField(blank=True)
    address = models.TextField(blank=True)
    id_number = models.CharField(
        max_length=50,
        blank=True,
        help_text='National ID or passport number'
    )
    customer_type = models.CharField(
        max_length=20,
        choices=[
            ('individual', 'Individual'),
            ('business', 'Business'),
            ('organization', 'Organization'),
        ],
        default='individual'
    )
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'customer'
        verbose_name = 'Customer'
        verbose_name_plural = 'Customers'
        ordering = ['name']
        indexes = [
            models.Index(fields=['phone_number']),
            models.Index(fields=['name']),
            models.Index(fields=['customer_type']),
        ]

    def __str__(self):
        return f"{self.name} - {self.phone_number}"

    def get_total_purchases(self, business=None):
        """Get total purchase amount for customer."""
        # This would aggregate across all sales
        # Implementation depends on specific requirements
        pass


# =============================================================================
# AUDIT LOGGING (7-Year Retention - KRA Compliance)
# =============================================================================

class AuditLog(models.Model):
    """
    Comprehensive audit log for all changes.

    Tracks CREATE, UPDATE, DELETE operations on critical tables.
    7-year retention required for KRA compliance.
    """

    ACTION_CHOICES = [
        ('create', 'Create'),
        ('update', 'Update'),
        ('delete', 'Delete'),
        ('login', 'User Login'),
        ('logout', 'User Logout'),
        ('export', 'Data Export'),
    ]

    id = models.BigAutoField(primary_key=True)
    table_name = models.CharField(max_length=100, db_index=True)
    record_id = models.BigIntegerField(db_index=True)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    old_data = models.JSONField(blank=True, null=True)
    new_data = models.JSONField(blank=True, null=True)
    changed_fields = models.JSONField(
        blank=True,
        null=True,
        help_text='List of fields that changed'
    )
    changed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='audit_logs'
    )
    business = models.ForeignKey(
        Business,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    user_agent = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'audit_log'
        verbose_name = 'Audit Log'
        verbose_name_plural = 'Audit Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['table_name', 'record_id']),
            models.Index(fields=['business', 'created_at']),
            models.Index(fields=['changed_by', 'created_at']),
            models.Index(fields=['action', 'created_at']),
        ]

    def __str__(self):
        return f"{self.action} on {self.table_name} #{self.record_id} by {self.changed_by} at {self.created_at}"


# =============================================================================
# DATABASE TRIGGERS (Implemented via Django Signals)
# =============================================================================

"""
Note: PostgreSQL triggers will be implemented using Django signals.

Key signals to implement:

1. JournalEntry post_save:
   - Create ledger entries for each line
   - Update account balances

2. WaterSale post_save:
   - Reduce water inventory
   - Create journal entry

3. LaundryJob post_save:
   - Update customer balance
   - Create journal entry

4. RetailSale post_save:
   - Reduce retail inventory
   - Create journal entry

5. All models post_save and pre_delete:
   - Create audit log entries

Signal handlers will be defined in signals.py file.
"""

# =============================================================================
# END OF MODELS
# =============================================================================

"""
MODEL COUNT SUMMARY:
- User Management: 3 models
- Business Configuration: 3 models
- Financial Core: 8 models
- Water Business: 4 models
- Laundry Business: 5 models
- Retail Business: 7 models
- Shared/Cross-Business: 1 model
- Audit: 1 model

TOTAL: 32 models

NEXT STEPS:
1. Create Django apps for each domain
2. Copy models to respective apps
3. Create and run migrations
4. Set up admin interface
5. Implement signal handlers
6. Create seed data
7. Write tests
"""

# LupinusBuild Product Roadmap

## Purpose

LupinusBuild is a multi-role project operations and financial management platform for construction, installation, fabrication, and field-service companies. MaxShade is the initial internal deployment. The long-term product will be distributed through the web, Apple App Store, and Google Play.

This document is the source of truth for agreed requirements, permissions, financial rules, workflows, security expectations, and launch priorities.

## Product principles

- Mobile-friendly field workflows
- Strict company and role isolation
- Granular financial permissions
- Complete audit history
- Every actual cost recorded once
- Forecast and realized profitability kept separate
- Secure private document storage
- Production-quality PDF and CSV exports
- No storage of full payment-card credentials

## Current foundation

The application currently includes authentication, password recovery, persistent sessions, company branding, role permissions, customers, leads, quotes, proposals, proposal PDFs, quote workflow/history, approved-quote conversion, projects, project costs, materials, files, notes, activities, task assignment, secure assignment notifications, an in-app notification inbox, and a Company Task Center.

## Roles and financial permissions

Roles describe operational authority. Additional permissions control sensitive financial capabilities.

- **Primary Admin:** full operational and financial access, approvals, reconciliation, payroll, overhead, profitability, users, cards, and settings.
- **CFO:** full financial access, payroll, overhead, approvals, reconciliation, reporting, and exports.
- **Admin:** operational management and direct-cost entry. Payroll, overhead, and full profitability require explicit permission.
- **Manager:** operational work, expense/time submission, and optional review. No automatic payroll or company-profit access.
- **Field User:** assigned work, daily expense/time/mileage submission, receipt capture, and access to their own submissions. Cannot approve their own expenses.
- **Viewer:** read-only access where granted; financial information is hidden by default.

Card ownership must not create separate roles. Use granular permissions such as:

- `has_company_card`
- `can_submit_card_expenses`
- `can_view_own_card_transactions`
- `can_code_own_transactions`
- `can_review_card_transactions`
- `can_approve_card_expenses`
- `can_reconcile_card_statements`
- `can_manage_card_accounts`
- `can_view_pay_rates`
- `can_manage_pay_rates`
- `can_view_overhead`
- `can_manage_overhead`
- `can_view_company_profitability`

## Unified expense ledger

Every actual cost must enter one canonical ledger to prevent duplicate expenses. Each record should include company, project or overhead designation, category, vendor/contractor/employee, date, description, estimated amount, actual amount, payment method, receipt/invoice, submitter, approval status, approver, reconciliation status, and audit timestamps.

Direct project categories:

- Materials
- Employee labor
- Third-party contractors
- Permits
- Rental equipment
- Engineering
- Fuel
- Mileage and travel
- Freight and delivery
- Disposal
- Other direct costs

Workflow:

```text
Draft -> Submitted -> Under Review -> Approved/Rejected -> Reconciled
```

Reconciled periods are locked. Corrections require an audit event.

## Materials

Track project, vendor, description, quantity, unit, estimated cost, actual cost, tax, freight, delivery, purchase date, payment method, receipt/invoice, delivery status, and usage status. Material costs feed the unified ledger once and must not be duplicated in stage costs.

## Employee labor

Track employee, work week, project, hours, effective hourly rate, labor burden, actual labor cost, and approval status.

```text
Actual labor cost = hours x burdened hourly rate
```

Labor burden may include employer taxes, workers' compensation, benefits, and other employer-paid costs. Hours are allocated across projects; office/unassigned time becomes overhead. Pay rates are effective-dated and restricted to authorized users.

## Third-party contractors

Track contractor/company, contacts, trade, W-9 status, insurance, project, scope, original contract, change orders, invoices, approved amount, paid amount, remaining commitment, due date, status, contracts, lien waivers, and audit history.

```text
Committed cost = original contract + approved change orders
Remaining commitment = committed cost - approved actual invoices
```

Forecast profit uses commitments; realized profit uses approved actual invoices.

## Permits and rentals

Permit records include project, jurisdiction, permit type/number, application date, estimated fee, actual fee, status, receipt, and documents.

Rental records include project, vendor, equipment, rental dates, base charge, delivery/pickup, fuel, tax, damage/cleaning fees, final cost, receipt, and invoice.

## Monthly overhead

Keep overhead separate from direct project costs. Categories include office payroll, rent, insurance, vehicles, software, utilities, accounting/legal, marketing, phone/internet, general equipment, and other administrative costs.

```text
Company operating profit = total project gross profit - monthly overhead
```

Future overhead allocation may use revenue, labor hours, or a configured percentage, while remaining distinguishable from direct costs.

## Credit cards and fuel cards

Never store full card numbers, CVV codes, or banking credentials. Store card nickname, issuer, last four digits, cardholder, status, and spending limit.

Transactions are entered manually or imported by CSV initially, then matched to receipts, assigned to a project/overhead, categorized, reviewed, approved, and reconciled.

Accounting rules:

- The purchase is the expense.
- Paying the card bill is a transfer, not another expense.
- Refunds and credits are negative transactions.
- Invoices and their card payments are matched, not counted twice.
- Unassigned transactions remain in Needs Review.
- Duplicate detection is required.
- Fuel transactions may track employee, vehicle, gallons, and odometer.

## Field expense submission

Field Users can submit company-card, fuel-card, personal reimbursement, cash, mileage, and other approved expenses throughout the day.

Flow:

1. Select project or overhead.
2. Select vendor.
3. Select category and payment method.
4. Enter amount, date, and business purpose.
5. Capture or upload receipt.
6. Submit for review.
7. Admin/CFO reviews.
8. CFO reconciles applicable card activity.

Employees cannot approve their own expenses.

## Receipts and documents

Support camera capture, photo selection, and JPEG/PNG/HEIC/PDF upload where available. Include preview, crop, rotate, retake, compression, readability checks, private Supabase Storage, company-scoped paths, Storage RLS, signed URLs, uploader/time metadata, and documented receipt exceptions.

Future extraction may suggest vendor, date, total, tax, last four card digits, receipt number, and duplicates. Employees must confirm extracted data.

## Vendor directory

Use a centralized vendor dropdown with name, category, contacts, status, preferred indicator, terms, W-9 status, insurance expiration, default category, and notes. Field Users may request new vendors; Admin/CFO approval prevents duplicates and makes them selectable.

## Expense notifications

Use immediate alerts for high-value expenses, reimbursements, missing receipts, declined cards, duplicates, unusual vendors, limit violations, and high-value contractor/rental/permit costs. Use daily digests for routine submissions, weekly unresolved reminders, and a review-queue badge to avoid alert fatigue.

## Profitability

Provide monthly, quarterly, annual, previous-year, and custom-range reporting.

```text
Actual project profit = contract revenue - all direct project costs
Gross margin % = actual project profit / contract revenue x 100
```

- Open projects appear under Forecast Profitability.
- Completed projects appear under Realized Profitability.
- Initial completed-project reporting uses completion date.
- Open work must not inflate realized profit.
- Initial reports are labeled Project Gross Profitability until overhead and revenue/payment data support true company net profit.

The Profitability Center includes YTD revenue/cost/profit/margin, current and prior quarter, open forecast, completed realized profit, best/worst projects, estimated-versus-actual variance, and category breakdowns.

## Reports and exports

Filter by project, multiple projects, all projects, date range, month/quarter/year, project status, vendor, category, employee/card, and approval/reconciliation status.

Project expense PDFs group materials, labor, contractors, permits, rentals, fuel/travel, and other costs. Summaries include contract amount, category totals, total actual cost, gross profit, and margin.

Support receipt references or appendices and ZIP packages containing PDF, CSV, receipts, invoices, contractor documents, and supporting records. CSV export is required for accounting and reconciliation.

## Security and audit

- Company-scoped RLS for records and storage
- Server-side permission enforcement
- Private financial documents
- No sensitive card credentials
- Immutable audit history
- No self-approval
- Locked reconciled periods
- Duplicate detection
- Project/company validation
- Least privilege
- Production logging and monitoring
- Backup and recovery procedures

## Internal launch priorities

1. Automatic notification refresh
2. Remove stale dashboard content
3. Custom SMTP and recovery verification
4. HTTPS production deployment and auth redirects
5. Error monitoring and logging
6. Full role regression testing
7. Remaining Supabase RLS audit
8. Backup/recovery procedures
9. MaxShade acceptance testing
10. Unified expense ledger and vendor directory
11. Receipt capture and approval queues
12. Card CSV import and reconciliation
13. Labor, contractors, permits, rentals, and overhead
14. Profitability Center and exports

## App Store roadmap

- Final name, branding, bundle identifiers, icons, and splash screens
- Apple/Google developer accounts and signing
- Responsive device testing
- Camera, photo-library, and file permissions
- Native push notifications
- Privacy policy, support URL, and data-use disclosures
- Store screenshots, descriptions, and metadata
- TestFlight and Google Play internal testing
- Release builds and store review

## Delivery strategy

1. Stabilize and deploy the internal web app.
2. Collect MaxShade production feedback.
3. Build the expense and financial ledger.
4. Add profitability and exports.
5. Complete native camera and push functionality.
6. Run TestFlight and Play internal testing.
7. Submit public store releases.

Future changes to financial rules, permissions, workflows, or reporting should update this document in the same commit as related code whenever practical.

# Product Requirements Document (PRD)

## ShopStock: Mobile Stock Management App for Small Grocery Shops & Pharmacies

**Prepared by:** Wavezly  
**Version:** 1.2  
**Date:** January 8, 2026  
**Status:** Draft

---

## Executive Summary

ShopStock is a simple, minimal mobile application designed to help small grocery shop and pharmacy owners efficiently manage their inventory using smartphone-based barcode scanning. The app eliminates the need for expensive POS systems or dedicated hardware while providing essential inventory tracking, expiry management, sales logging, due/credit management, and basic analytics.

---

## 1. Problem Statement

### Current Situation

Small grocery shops and pharmacies often manage inventory manually using paper logs or basic spreadsheets. Most lack access to affordable, easy-to-use digital tools for tracking products, sales, and expiry dates.

### User Pain Points

| Pain Point | Impact |
|------------|--------|
| Manual tracking is time-consuming and error-prone | Hours lost daily on inventory management |
| Difficulty tracking expiry dates (especially medicines) | Revenue loss from expired products |
| No visibility into fast/slow-moving products | Poor purchasing decisions |
| No tracking of customer dues/credit | Lost revenue from unpaid dues |
| Lack of sales analytics | Missed optimization opportunities |
| Limited budget for expensive POS/barcode scanners | Barrier to digital adoption |

### Business Impact

- **Revenue loss** from expired or overstocked products
- **Unpaid dues** from customers buying on credit
- **Inefficient restocking** leading to out-of-stock situations
- **Poor decision-making** due to lack of sales and inventory data

---

## 2. Proposed Solution

### Overview

A simple, minimal mobile application enabling small shop owners to:
- Manage inventory via phone camera-based barcode scanning
- Track expiry dates with automated alerts
- Log sales and automatically update stock levels
- Manage customer dues/credit with SMS reminders
- View daily and monthly sales reports

### Target Users

| User Type | Description | Primary Needs |
|-----------|-------------|---------------|
| Small Grocery Shop Owners | Independent store operators with 100-5000 SKUs | Simple inventory tracking, sales logging |
| Pharmacy Owners | Medicine retailers with strict expiry requirements | Expiry alerts, due management |
| Shop Staff | Employees managing daily operations | Quick product lookup, stock updates |

### User Roles

| Role | Permissions |
|------|-------------|
| Shop Owner | Full access - manage products, sales, dues, reports, staff |
| Staff | Limited access - log sales, view products, add dues |

---

## 3. User Stories

### Core User Stories

1. **Product Entry**  
   *As a shop owner, I want to add products via barcode or manual entry so that I can track all items in my inventory.*

2. **Expiry Notifications**  
   *As a shop owner, I want to receive notifications for products nearing expiry so that I can take action before loss occurs.*

3. **Sales Logging**  
   *As a shop owner, I want to log daily sales and automatically update stock so that I can monitor business performance easily.*

4. **Due Management**  
   *As a shop owner, I want to track customer dues and send SMS reminders so that I can collect pending payments.*

5. **Sales Reports**  
   *As a shop owner, I want to view daily and monthly sales reports so that I can understand my business performance.*

6. **Staff Management**  
   *As a shop owner, I want to add staff members with limited access so that they can help with daily operations.*

---

## 4. Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Inventory adoption | 80% of users add ≥50% of inventory within first week | App analytics |
| Expiry notification effectiveness | 90% of users receive timely alerts | Push notification delivery rate |
| Sales logging retention | 70% of users regularly log sales after first month | Daily active usage |
| Due collection improvement | 40% improvement in due collection for active users | User surveys |
| User satisfaction | NPS score ≥ 40 | In-app surveys |

---

## 5. Functional Requirements

### 5.1 Product Management

| Feature | Description | Priority |
|---------|-------------|----------|
| Manual product entry | Add/edit/delete products with name, price, quantity | P0 (Must Have) |
| Barcode scanning | Add products via phone camera scan (UPC/EAN codes) | P0 (Must Have) |
| Product details | Store: name, SKU, price, cost, quantity, expiry date, category | P0 (Must Have) |
| Product search | Quick search by name or barcode | P0 (Must Have) |
| Product images | Capture/store product photos | P2 (Nice to Have) |
| Bulk import | Import products via CSV file | P2 (Nice to Have) |

### 5.2 Inventory Tracking

| Feature | Description | Priority |
|---------|-------------|----------|
| Real-time stock levels | Display current quantity for all products | P0 (Must Have) |
| Auto stock update | Automatically decrease stock on sale logging | P0 (Must Have) |
| Low-stock alerts | Configurable threshold notifications | P0 (Must Have) |
| Expiry alerts | Customizable notification periods (7/14/30/60/90 days) | P0 (Must Have) |
| Stock adjustment | Manual stock corrections with reason logging | P1 (Should Have) |

### 5.3 Sales Management

| Feature | Description | Priority |
|---------|-------------|----------|
| Quick sale logging | Scan or search to log sales | P0 (Must Have) |
| Daily sales report | View total sales, items sold, revenue for today | P0 (Must Have) |
| Monthly sales report | View total sales, items sold, revenue for month | P0 (Must Have) |
| Sales history | Searchable log of all transactions | P0 (Must Have) |
| Return handling | Process returns and restore stock | P1 (Should Have) |

### 5.4 Due/Credit Management

| Feature | Description | Priority |
|---------|-------------|----------|
| Add customer | Add customer with name and phone number | P0 (Must Have) |
| Record due | Record credit/due amount against customer | P0 (Must Have) |
| Due history | View all dues for a customer | P0 (Must Have) |
| Due payment | Record partial or full payment against dues | P0 (Must Have) |
| SMS reminder | Send SMS to customer with due amount | P0 (Must Have) |
| Due summary | View total pending dues across all customers | P0 (Must Have) |
| Overdue alerts | Notification for dues older than X days | P1 (Should Have) |

### 5.5 Reports

| Feature | Description | Priority |
|---------|-------------|----------|
| Daily sales report | Sales, revenue, profit for selected day | P0 (Must Have) |
| Monthly sales report | Sales, revenue, profit for selected month | P0 (Must Have) |
| Fast/slow movers | Identify top and bottom performing products | P1 (Should Have) |
| Expiry report | List of products expiring within selected period | P0 (Must Have) |
| Low stock report | Products below threshold | P0 (Must Have) |
| Due report | List of all pending customer dues | P0 (Must Have) |
| Export functionality | CSV/PDF export for reports | P1 (Should Have) |

### 5.6 User Management

| Feature | Description | Priority |
|---------|-------------|----------|
| Shop owner account | Full access to all features | P0 (Must Have) |
| Staff accounts | Limited access (log sales, view products, add dues) | P1 (Should Have) |
| Add/remove staff | Shop owner can manage staff members | P1 (Should Have) |
| Activity log | Track staff actions (who sold what) | P2 (Nice to Have) |

### 5.7 Admin Panel (Web Dashboard)

The admin panel is a web-based dashboard for the Wavezly team to manage the platform, users, and system settings.

#### 5.7.1 Dashboard & Analytics

| Feature | Description | Priority |
|---------|-------------|----------|
| Overview dashboard | Total users, active users, revenue metrics | P0 (Must Have) |
| User growth charts | Daily/weekly/monthly signups visualization | P0 (Must Have) |
| Usage analytics | App opens, feature usage, retention rates | P1 (Should Have) |
| Geographic distribution | Users by region/country map view | P1 (Should Have) |
| Revenue dashboard | Subscription revenue, MRR, churn rate | P1 (Should Have) |

#### 5.7.2 User Management

| Feature | Description | Priority |
|---------|-------------|----------|
| User list | Searchable, filterable list of all users | P0 (Must Have) |
| User details | View individual user profile, shop info, activity | P0 (Must Have) |
| User status | Activate/deactivate/suspend accounts | P0 (Must Have) |
| Subscription management | View/modify user subscription plans | P1 (Should Have) |
| Impersonation | Login as user for support (with audit log) | P1 (Should Have) |

#### 5.7.3 Notification Management

| Feature | Description | Priority |
|---------|-------------|----------|
| Push notification composer | Create and send push notifications via OneSignal | P0 (Must Have) |
| Segment targeting | Send to specific user segments | P1 (Should Have) |
| Scheduled notifications | Schedule notifications for later | P1 (Should Have) |
| In-app announcements | Create banners/modals for app | P1 (Should Have) |
| Notification history | View sent notifications and delivery stats | P1 (Should Have) |

#### 5.7.4 SMS Management

| Feature | Description | Priority |
|---------|-------------|----------|
| SMS credits management | View and allocate SMS credits to users | P0 (Must Have) |
| SMS usage logs | Track SMS sent by users | P0 (Must Have) |
| SMS templates | Manage default SMS templates | P1 (Should Have) |

#### 5.7.5 Subscription & Billing

| Feature | Description | Priority |
|---------|-------------|----------|
| Plan management | Create/edit subscription plans and pricing | P1 (Should Have) |
| Coupon/promo codes | Create discount codes for users | P1 (Should Have) |
| Payment history | View all transactions | P1 (Should Have) |

#### 5.7.6 Support

| Feature | Description | Priority |
|---------|-------------|----------|
| Support tickets | View and respond to user support requests | P0 (Must Have) |
| Ticket assignment | Assign tickets to team members | P1 (Should Have) |
| User feedback | View app store reviews, in-app feedback | P1 (Should Have) |

#### 5.7.7 System Settings

| Feature | Description | Priority |
|---------|-------------|----------|
| App configuration | Feature flags, maintenance mode | P0 (Must Have) |
| Admin users | Create/manage admin accounts with roles | P0 (Must Have) |
| Audit logs | Track all admin actions | P1 (Should Have) |

---

## 6. Technical Requirements

### 6.1 Platform

| Requirement | Specification |
|-------------|---------------|
| Primary Platform | Android (API 24+, Android 7.0+) |
| Secondary Platform | iOS (Phase 2) |
| Framework | Flutter 3.x (Dart) |
| Minimum Device | 2GB RAM, 720p display |

### 6.2 Tech Stack Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     MOBILE APP (Flutter)                     │
│  ┌─────────────┬─────────────┬─────────────┬──────────────┐ │
│  │   Riverpod  │    Dio      │  sqflite    │  go_router   │ │
│  │   (State)   │   (HTTP)    │  (Local DB) │  (Navigation)│ │
│  └─────────────┴─────────────┴─────────────┴──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        BACKEND                               │
│                       Supabase                               │
│  ┌─────────────┬─────────────┬─────────────┬──────────────┐ │
│  │  PostgreSQL │    Auth     │   Storage   │   Realtime   │ │
│  │  (Database) │   (Users)   │  (Images)   │   (Sync)     │ │
│  └─────────────┴─────────────┴─────────────┴──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌───────────────────┐ ┌─────────────┐ ┌─────────────────────┐
│    OneSignal      │ │  SMS API    │ │   ADMIN PANEL       │
│  (Push Alerts)    │ │ (Due SMS)   │ │  (Next.js + Vercel) │
└───────────────────┘ └─────────────┘ └─────────────────────┘
```

### 6.3 Key Flutter Packages

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Supabase SDK for Flutter |
| `onesignal_flutter` | OneSignal push notifications |
| `mobile_scanner` | ML Kit barcode scanning |
| `sqflite` | Local SQLite database |
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | Encrypted local storage |
| `pdf` | PDF report generation |
| `csv` | CSV export |
| `flutter_local_notifications` | Local notifications |
| `url_launcher` | Open SMS app |

### 6.4 Admin Panel Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Next.js 14 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| UI Components | shadcn/ui |
| Charts | Recharts |
| Auth | Supabase Auth (admin roles) |
| Hosting | Vercel |

### 6.5 Backend & Database

| Component | Specification |
|-----------|---------------|
| Local Database | SQLite for offline-first operation |
| Cloud Database | Supabase (PostgreSQL) for cloud sync |
| Authentication | Supabase Auth (email, phone, Google) |
| API Layer | Supabase REST API + Realtime subscriptions |
| Storage | Supabase Storage for product images |

### 6.6 Barcode Scanning

| Requirement | Specification |
|-------------|---------------|
| Technology | ML Kit Barcode Scanning via mobile_scanner |
| Supported Formats | UPC-A, UPC-E, EAN-8, EAN-13, Code 128, QR Code |
| Performance | < 500ms scan-to-result |
| Offline Support | Must work without internet |

### 6.7 Notifications

| Requirement | Specification |
|-------------|---------------|
| Push Notifications | OneSignal for expiry/low-stock alerts |
| Local Notifications | Flutter Local Notifications for offline alerts |
| SMS Service | Twilio / local SMS gateway for due reminders |

### 6.8 SMS Integration

| Requirement | Specification |
|-------------|---------------|
| SMS Provider | Twilio / local provider (e.g., SSL Wireless for BD) |
| SMS Trigger | Manual send by shop owner or scheduled reminder |
| SMS Content | "Dear [Name], your due amount at [Shop] is [Amount] BDT. Please pay soon." |
| SMS Credits | Prepaid SMS credits system |
| Delivery Status | Track SMS delivery status |

### 6.9 Data Security

| Requirement | Specification |
|-------------|---------------|
| Local Encryption | AES-256 for sensitive data |
| Cloud Security | Supabase Row Level Security (RLS), HTTPS only |
| API Security | Supabase JWT tokens |
| Backup | Automatic local backup, Supabase automatic backups |

### 6.10 Supabase Database Schema

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  shop_name TEXT,
  phone TEXT,
  language TEXT DEFAULT 'en',
  role TEXT DEFAULT 'owner',
  owner_id UUID REFERENCES profiles(id),
  sms_credits INTEGER DEFAULT 0,
  subscription_plan TEXT DEFAULT 'free',
  onesignal_player_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  barcode TEXT,
  name TEXT NOT NULL,
  category TEXT,
  price DECIMAL(10,2),
  cost DECIMAL(10,2),
  quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  expiry_date DATE,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sales
CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id),
  customer_id UUID REFERENCES customers(id),
  total_amount DECIMAL(10,2),
  paid_amount DECIMAL(10,2),
  due_amount DECIMAL(10,2) DEFAULT 0,
  payment_method TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sale Items
CREATE TABLE sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers (for due management)
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  total_due DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dues
CREATE TABLE dues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  sale_id UUID REFERENCES sales(id),
  amount DECIMAL(10,2) NOT NULL,
  paid_amount DECIMAL(10,2) DEFAULT 0,
  remaining_amount DECIMAL(10,2),
  status TEXT DEFAULT 'pending',
  due_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Due Payments
CREATE TABLE due_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  due_id UUID REFERENCES dues(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT,
  received_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SMS Logs
CREATE TABLE sms_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id),
  phone TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'sent',
  provider_response JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stock Adjustments
CREATE TABLE stock_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  previous_qty INTEGER,
  new_qty INTEGER,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support Tickets
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin Users
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  role TEXT DEFAULT 'support',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES admin_users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own products" ON products
  FOR ALL USING (auth.uid() = user_id);

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own sales" ON sales
  FOR ALL USING (auth.uid() = user_id);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own customers" ON customers
  FOR ALL USING (auth.uid() = user_id);

ALTER TABLE dues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own dues" ON dues
  FOR ALL USING (auth.uid() = user_id);
```

---

## 7. Design Requirements

### 7.1 UI/UX Principles

- **Simple & Minimal:** Clean, uncluttered interface
- **Large Touch Targets:** Minimum 48dp for easy tapping
- **Readable Typography:** 16sp+ base font size
- **High Contrast:** Easy to read in all lighting
- **Offline-First:** All core features work without internet
- **Fast:** App should feel snappy and responsive

### 7.2 Mobile App Navigation

```
┌─────────────────────────────────────────┐
│              Bottom Navigation           │
├────────┬────────┬────────┬──────────────┤
│  Home  │ Sales  │  Dues  │   More       │
│   🏠   │   💰   │   📋   │    ⋯        │
└────────┴────────┴────────┴──────────────┘

More Menu:
├── Inventory
├── Reports
├── Staff (Owner only)
├── Settings
└── Help & Support
```

### 7.3 Key Screens

| Screen | Purpose |
|--------|---------|
| Home | Quick stats, alerts, quick actions |
| Sales | Log new sale, today's sales |
| Dues | Customer list with dues, send SMS |
| Inventory | Product list, add/edit products |
| Reports | Daily/monthly sales, expiry list |
| Settings | Profile, notifications, language |

### 7.4 Visual Indicators

| Status | Color | Usage |
|--------|-------|-------|
| Expired | Red (#F44336) | Products past expiry |
| Near Expiry | Orange (#FF9800) | Products expiring soon |
| Low Stock | Yellow (#FFC107) | Below threshold |
| Overdue | Red (#F44336) | Dues past due date |
| In Stock | Green (#4CAF50) | Healthy levels |

### 7.5 Localization

| Language | Priority |
|----------|----------|
| English | P0 (Launch) |
| Bengali (বাংলা) | P0 (Launch) |

---

## 8. Release Phases

### Phase 1: MVP (Month 1-3)

**Mobile App:**
- Manual product entry + barcode scanning
- Basic inventory tracking
- Expiry and low-stock alerts
- Simple sales logging
- Daily sales report
- Offline-first with SQLite
- Android only

**Admin Panel:**
- Basic dashboard with user counts
- User list and search

### Phase 2: Core Features (Month 4-6)

**Mobile App:**
- Cloud sync with Supabase
- User authentication
- Due/credit management
- SMS reminders for dues
- Monthly sales report
- OneSignal push notifications
- iOS release

**Admin Panel:**
- Full analytics dashboard
- Push notification composer
- SMS credits management
- Support ticket system

### Phase 3: Enhanced (Month 7-9)

**Mobile App:**
- Staff accounts (Shop Owner + Staff roles)
- Export reports (CSV/PDF)
- Fast/slow mover analytics
- Bengali language support

**Admin Panel:**
- Subscription management
- User impersonation for support
- Advanced reporting

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Poor barcode scanning | Medium | High | Use ML Kit, manual entry fallback |
| Low user adoption | Medium | High | Simple UI, local language support |
| SMS delivery failures | Medium | Medium | Use reliable provider, show delivery status |
| Data loss | Medium | High | Auto backup, cloud sync |
| Slow on low-end devices | Medium | Medium | Optimize for 2GB RAM |

---

## 10. Open Questions

1. What is the pricing model (free, freemium, subscription)?
2. Which SMS provider for Bangladesh market?
3. How many free SMS credits per month?
4. Should we integrate with bKash/Nagad for payment tracking?
5. Do we need receipt printing via Bluetooth printer?

---

## 11. Appendix

### A. SMS Templates

**Due Reminder (English):**
```
Dear [Customer Name], your due amount at [Shop Name] is [Amount] BDT. Please pay at your earliest convenience. Thank you!
```

**Due Reminder (Bengali):**
```
প্রিয় [Customer Name], [Shop Name] এ আপনার বকেয়া পরিমাণ [Amount] টাকা। অনুগ্রহ করে যত তাড়াতাড়ি সম্ভব পরিশোধ করুন। ধন্যবাদ!
```

### B. User Roles Summary

| Permission | Shop Owner | Staff |
|------------|------------|-------|
| View products | ✅ | ✅ |
| Add/edit products | ✅ | ❌ |
| Log sales | ✅ | ✅ |
| View sales history | ✅ | ✅ (own) |
| Manage dues | ✅ | ✅ (add only) |
| Send SMS | ✅ | ❌ |
| View reports | ✅ | ❌ |
| Manage staff | ✅ | ❌ |
| Settings | ✅ | Limited |

### C. Glossary

| Term | Definition |
|------|------------|
| SKU | Stock Keeping Unit - unique product identifier |
| UPC | Universal Product Code - barcode standard |
| Due | Credit amount owed by customer |
| RLS | Row Level Security - database protection |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 8, 2026 | Wavezly | Initial draft |
| 1.1 | Jan 8, 2026 | Wavezly | Added tech stack, admin panel |
| 1.2 | Jan 8, 2026 | Wavezly | Simplified features, removed shop layout & batch tracking, added due management with SMS, added user roles (Shop Owner/Staff) |

---

*This PRD provides a blueprint for building a simple, minimal stock management app focused on essential features for small shops and pharmacies.*

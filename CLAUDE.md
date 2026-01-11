# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ShopStock** - A mobile stock management application for small grocery shops and pharmacies. Users can manage inventory, track expiry dates, log sales, and manage customer dues via smartphone barcode scanning.

- **Framework**: Flutter 3.x (Dart >= 3.0.0)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Platform**: Android (primary), iOS (planned)
- **Working Directory**: `warehouse_management/` (Flutter project root)

## Development Commands

All commands should be run from `warehouse_management/` directory:

```bash
# Navigate to project directory
cd warehouse_management

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Clean build cache
flutter clean

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Architecture Overview

### Project Structure Pattern
```
warehouse_management/
├── lib/
│   ├── main.dart              # Entry point with Supabase initialization
│   ├── my_app.dart            # Root MaterialApp with auth state routing
│   ├── config/
│   │   └── supabase_config.dart  # Supabase credentials & initialization
│   ├── models/               # Data entities (Product, Sale, Customer, etc.)
│   ├── services/             # Business logic layer (Auth, Product, Sales, Customer, Barcode)
│   ├── screens/              # UI screens (30+ screens)
│   ├── widgets/              # Reusable UI components
│   ├── utils/                # Utilities (colors, helpers)
│   └── functions/            # Helper functions (toast, dialogs)
```

### Architecture Pattern
**MVC-like with Service Layer:**
- **Models**: Data entities with Supabase serialization (`toJson()`, `fromJson()`)
- **Services**: Business logic & Supabase integration (AuthService, ProductService, SalesService, CustomerService, BarcodeService)
- **Screens**: UI layer consuming services
- **Widgets**: Reusable components

### Data Flow
1. Screens call Services for business logic
2. Services interact with Supabase backend
3. Models handle data serialization/deserialization
4. Screens rebuild on state changes

## Key Technical Details

### Supabase Integration
- **URL**: `https://ozadmtmkrkwbolzbqtif.supabase.co`
- **Config**: `lib/config/supabase_config.dart`
- **Client Access**: `SupabaseConfig.client` (global accessor)
- **Auth State**: Stream-based in `my_app.dart` (`authStateChanges()`)
- **RLS**: Row Level Security enabled - users only see their own data

### Authentication Flow
- Email/password authentication via Supabase Auth
- Auth state streaming determines Login vs MainNavigation routing
- Services: `lib/services/auth_service.dart`

### Navigation Structure
**Bottom Navigation (5 tabs + QR FAB):**
```
[Home] [Inventory] [QR Scanner] [Customers] [Settings]
   0        1           2            3          4
```
Implemented in: `lib/screens/main_navigation.dart`

### Database Schema
Tables: `products`, `sales`, `sale_items`, `customers`, `customer_transactions`, `dues`, `due_payments`, `sms_logs`, `stock_adjustments`, `profiles`

SQL Setup: `supabase_setup.sql` (must be executed in Supabase SQL Editor first)

### Core Services
| Service | File | Responsibility |
|---------|------|----------------|
| AuthService | `lib/services/auth_service.dart` | User signup, login, logout |
| ProductService | `lib/services/product_service.dart` | Product CRUD operations |
| SalesService | `lib/services/sales_service.dart` | Sales logging, transaction management |
| CustomerService | `lib/services/customer_service.dart` | Customer & due management |
| BarcodeService | `lib/services/barcode_service.dart` | Barcode scanning logic |

### Key Dependencies
```yaml
supabase_flutter: ^2.5.10      # Backend & auth
mobile_scanner: ^5.2.3          # Barcode scanning (ML Kit)
flutter_svg: ^2.0.10            # SVG rendering
cached_network_image: ^3.4.1    # Image caching
fluttertoast: ^8.2.8           # Toast notifications
intl: ^0.19.0                   # Date formatting
```

## Development Status

**Completed:**
- ✅ Supabase integration (migrated from Firebase)
- ✅ Core services (Auth, Product, Sales, Customer, Barcode)
- ✅ Database schema & models
- ✅ Main navigation structure
- ✅ 30+ UI screens

**In Progress:**
- ⏳ Screen migrations to use services (7-8 screens need updates from Firebase to Supabase)
- ⏳ Supabase SQL schema execution
- ⏳ Testing and validation

**Pattern for Migration:**
```dart
// OLD (Firebase):
FirebaseFirestore.instance.collection('products')...

// NEW (Supabase):
ProductService().getProducts()...
```

## Common Development Patterns

### Adding New Screens
1. Create screen in `lib/screens/`
2. Use existing services for data operations
3. Follow Material Design patterns (consistent with existing screens)
4. Add to navigation if needed (update `main_navigation.dart`)

### Adding New Features
1. Check PRD.md for requirements alignment
2. Create/update models if needed (with Supabase serialization)
3. Create/update services for business logic
4. Implement UI screens
5. Test authentication flow if user-specific

### Working with Supabase
```dart
// Access client
final supabase = SupabaseConfig.client;

// Auth operations
await AuthService().signUp(email, password);
await AuthService().signIn(email, password);

// CRUD operations (example)
await ProductService().addProduct(product);
final products = await ProductService().getProducts();
```

### Barcode Scanning
- Uses ML Kit via `mobile_scanner` package
- Supports: UPC-A, UPC-E, EAN-8, EAN-13, Code 128, QR Code
- Implementation: `lib/services/barcode_service.dart`
- UI: `lib/screens/barcode_scanner_screen.dart`

## Important Notes

### Credentials Security
- ⚠️ Supabase credentials are currently hardcoded in `supabase_config.dart`
- For production: Move to environment variables or Flutter dotenv

### Testing Workflow
Before marking implementation complete:
1. User registration works
2. User login/logout works
3. Product CRUD operations work
4. Sales logging works
5. Customer/due management works
6. APK builds successfully (`flutter build apk --debug`)

### First-Time Setup
1. Execute `supabase_setup.sql` in Supabase SQL Editor
2. Run `flutter pub get`
3. Connect device/emulator
4. Run `flutter run`

### Database Migrations
- SQL scripts: `supabase_setup.sql`, `sales_migration.sql`
- Execute in Supabase dashboard SQL Editor
- Check IMPLEMENTATION_STATUS.md for migration status

## Design Guidelines

- **Fonts**: Nunito (primary), Open Sans, Inter
- **Colors**: Defined in `lib/utils/color_palette.dart`
- **UI Components**: Material Design with custom theming
- **Minimum Target**: Android 7.0+ (API 24+), 2GB RAM
- **Offline-First**: Local SQLite + Cloud sync (planned)

## Reference Documentation

- **PRD**: `PRD.md` (Product Requirements Document)
- **Implementation Status**: `warehouse_management/IMPLEMENTATION_STATUS.md`
- **Database Schema**: `warehouse_management/supabase_setup.sql`
- **Sales Migration**: `warehouse_management/sales_migration.sql`

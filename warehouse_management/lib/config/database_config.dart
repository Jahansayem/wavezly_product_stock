import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/customer_transaction.dart';
import 'supabase_config.dart';

class DatabaseConfig {
  static Database? _database;
  static const String _databaseName = 'wavezly.db';
  static const int _databaseVersion = 12;

  static Future<void> initialize() async {
    if (_database != null) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    // First-run migration: Migrate existing Supabase data to local
    if (await _isFirstRun()) {
      await _migrateFromSupabase();
    }
  }

  static Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations
    if (oldVersion < 2) {
      // Add missing columns for Supabase sync compatibility
      await db.execute('ALTER TABLE products ADD COLUMN sale_price REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN customer_phone TEXT');
      await db.execute(
          'ALTER TABLE sales ADD COLUMN payment_status TEXT DEFAULT "paid"');
      await db.execute('ALTER TABLE sales ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE sale_items ADD COLUMN product_id TEXT');
      print(
          'Database migrated to version 2: Added sale_price, customer_phone, payment_status, notes, product_id columns');
    }

    if (oldVersion < 3) {
      // Add extended product columns for complete Supabase sync compatibility
      await db.execute(
          'ALTER TABLE products ADD COLUMN sell_online INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE products ADD COLUMN wholesale_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE products ADD COLUMN wholesale_price REAL');
      await db
          .execute('ALTER TABLE products ADD COLUMN wholesale_min_qty INTEGER');
      await db.execute(
          'ALTER TABLE products ADD COLUMN stock_alert_enabled INTEGER DEFAULT 0');
      await db
          .execute('ALTER TABLE products ADD COLUMN min_stock_level INTEGER');
      await db.execute(
          'ALTER TABLE products ADD COLUMN vat_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE products ADD COLUMN vat_percent REAL');
      await db.execute(
          'ALTER TABLE products ADD COLUMN warranty_enabled INTEGER DEFAULT 0');
      await db
          .execute('ALTER TABLE products ADD COLUMN warranty_duration INTEGER');
      await db.execute('ALTER TABLE products ADD COLUMN warranty_unit TEXT');
      await db.execute(
          'ALTER TABLE products ADD COLUMN discount_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE products ADD COLUMN discount_value REAL');
      await db.execute('ALTER TABLE products ADD COLUMN discount_type TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN details TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN images TEXT');
      print(
          'Database migrated to version 3: Added 16 extended product columns for Supabase sync');
    }

    if (oldVersion < 4) {
      // Add quick sell columns to sales table
      await db.execute(
          'ALTER TABLE sales ADD COLUMN is_quick_sale INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE sales ADD COLUMN cash_received REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN profit_margin REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN product_details TEXT');
      await db.execute(
          'ALTER TABLE sales ADD COLUMN receipt_sms_sent INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE sales ADD COLUMN sale_date TEXT');
      await db.execute('ALTER TABLE sales ADD COLUMN photo_url TEXT');
      await db.execute('ALTER TABLE sales ADD COLUMN customer_id TEXT');
      print(
          'Database migrated to version 4: Added 8 quick sell columns to sales table');
    }

    if (oldVersion < 5) {
      // Add transaction_date column to customer_transactions for Supabase sync compatibility
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN transaction_date TEXT');
      print(
          'Database migrated to version 5: Added transaction_date column to customer_transactions');
    }

    if (oldVersion < 6) {
      // Add missing columns for complete Supabase sync compatibility
      // Products table: Bengali name and icon
      await db.execute('ALTER TABLE products ADD COLUMN name_bn TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN icon_name TEXT');

      // Customer transactions table: extended fields
      await db
          .execute('ALTER TABLE customer_transactions ADD COLUMN note TEXT');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN balance REAL DEFAULT 0');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN sms_enabled INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN image_url TEXT');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN transaction_subtype TEXT');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN attachment_url TEXT');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN sms_cost REAL');
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN reference_id TEXT');

      print(
          'Database migrated to version 6: Added name_bn, icon_name to products; note, balance, sms_enabled, image_url, transaction_subtype, attachment_url, sms_cost, reference_id to customer_transactions');
    }

    if (oldVersion < 7) {
      // Add updated_at column to customer_transactions for sync compatibility
      await db.execute(
          'ALTER TABLE customer_transactions ADD COLUMN updated_at TEXT');
      print(
          'Database migrated to version 7: Added updated_at column to customer_transactions');
    }

    if (oldVersion < 8) {
      // Add local_notifications table for OneSignal push notifications
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_notifications (
          notification_id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          additional_data TEXT,
          received_at TEXT NOT NULL,
          is_read INTEGER DEFAULT 0
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_local_notifications_received_at ON local_notifications(received_at DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_local_notifications_is_read ON local_notifications(is_read)');
      print(
          'Database migrated to version 8: Added local_notifications table for OneSignal');
    }

    if (oldVersion < 9) {
      // Add cashbox_transactions table for local-first cashbox
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cashbox_transactions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          transaction_type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          category TEXT,
          transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          last_synced_at TEXT
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cashbox_user_id ON cashbox_transactions(user_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cashbox_date ON cashbox_transactions(transaction_date)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cashbox_type ON cashbox_transactions(transaction_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cashbox_sync ON cashbox_transactions(is_synced)');
      print(
          'Database migrated to version 9: Added cashbox_transactions table for local-first cashbox');
    }

    if (oldVersion < 10) {
      // Add expense_categories and expenses tables for local-first expense module
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expense_categories (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          name TEXT NOT NULL,
          name_bengali TEXT NOT NULL,
          description TEXT,
          description_bengali TEXT,
          icon_name TEXT NOT NULL,
          icon_color TEXT NOT NULL,
          bg_color TEXT NOT NULL,
          is_system INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          last_synced_at TEXT
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON expense_categories(user_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expense_categories_is_system ON expense_categories(is_system)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expense_categories_sync ON expense_categories(is_synced)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          category_id TEXT,
          amount REAL NOT NULL,
          description TEXT,
          expense_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          last_synced_at TEXT
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_sync ON expenses(is_synced)');
      print(
          'Database migrated to version 10: Added expense_categories and expenses tables for local-first expense module');
    }

    if (oldVersion < 11) {
      // Add purchases and purchase_items tables for local-first purchase module
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          purchase_number TEXT NOT NULL,
          supplier_id TEXT,
          supplier_name TEXT,
          total_amount REAL NOT NULL,
          payment_status TEXT DEFAULT 'unpaid',
          payment_method TEXT,
          notes TEXT,
          purchase_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          last_synced_at TEXT,
          UNIQUE(purchase_number, user_id)
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(purchase_date DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchases_sync ON purchases(is_synced)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_items (
          id TEXT PRIMARY KEY,
          purchase_id TEXT NOT NULL,
          product_id TEXT,
          product_name TEXT NOT NULL,
          cost_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          total_cost REAL NOT NULL,
          created_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          last_synced_at TEXT,
          FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON purchase_items(product_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_purchase_items_sync ON purchase_items(is_synced)');
      print(
          'Database migrated to version 11: Added purchases and purchase_items tables for local-first purchase module');
    }

    if (oldVersion < 12) {
      // Align purchase tables with Supabase schema to prevent SQL column mismatch errors
      await _addColumnIfMissing(db, 'purchases', 'paid_amount', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'due_amount', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'cash_given', 'REAL');
      await _addColumnIfMissing(db, 'purchases', 'change_amount', 'REAL');
      await _addColumnIfMissing(db, 'purchases', 'receipt_image_path', 'TEXT');
      await _addColumnIfMissing(db, 'purchases', 'comment', 'TEXT');
      await _addColumnIfMissing(db, 'purchases', 'sms_enabled', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'receipt_number', 'TEXT');
      await _addColumnIfMissing(db, 'purchases', 'subtotal', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'delivery_charge', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'discount', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, 'purchases', 'receipt_image_url', 'TEXT');

      await _addColumnIfMissing(db, 'purchase_items', 'unit_price', 'REAL');
      await _addColumnIfMissing(db, 'purchase_items', 'total_price', 'REAL');

      print(
          'Database migrated to version 12: Aligned purchases and purchase_items columns with Supabase schema');
    }
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((col) => col['name'] == columnName);
    if (!exists) {
      await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
    }
  }

  static Future<void> _createSchema(Database db) async {
    // Products Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_bn TEXT,
        cost REAL,
        sale_price REAL,
        quantity INTEGER DEFAULT 0,
        product_group TEXT,
        location TEXT,
        company TEXT,
        description TEXT,
        image_url TEXT,
        barcode TEXT,
        expiry_date TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sell_online INTEGER DEFAULT 0,
        wholesale_enabled INTEGER DEFAULT 0,
        wholesale_price REAL,
        wholesale_min_qty INTEGER,
        stock_alert_enabled INTEGER DEFAULT 0,
        min_stock_level INTEGER,
        vat_enabled INTEGER DEFAULT 0,
        vat_percent REAL,
        warranty_enabled INTEGER DEFAULT 0,
        warranty_duration INTEGER,
        warranty_unit TEXT,
        discount_enabled INTEGER DEFAULT 0,
        discount_value REAL,
        discount_type TEXT,
        details TEXT,
        images TEXT,
        icon_name TEXT,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_group ON products(product_group)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_sync ON products(is_synced)');

    // Product Groups Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        UNIQUE(name, user_id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_groups_user_id ON product_groups(user_id)');

    // Locations Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        UNIQUE(name, user_id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_locations_user_id ON locations(user_id)');

    // Customers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        customer_type TEXT DEFAULT 'customer',
        total_due REAL DEFAULT 0,
        is_paid INTEGER DEFAULT 1,
        avatar_color TEXT,
        avatar_url TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_transaction_date TEXT,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_type ON customers(customer_type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_sync ON customers(is_synced)');

    // Customer Transactions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        note TEXT,
        balance REAL DEFAULT 0,
        sale_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        transaction_date TEXT,
        sms_enabled INTEGER DEFAULT 0,
        image_url TEXT,
        transaction_subtype TEXT,
        attachment_url TEXT,
        sms_cost REAL,
        reference_id TEXT,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_trans_customer_id ON customer_transactions(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_trans_user_id ON customer_transactions(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_trans_date ON customer_transactions(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_trans_sync ON customer_transactions(is_synced)');

    // Sales Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        sale_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        tax_amount REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        customer_name TEXT DEFAULT 'Walk-in Customer',
        customer_phone TEXT,
        payment_method TEXT DEFAULT 'cash',
        payment_status TEXT DEFAULT 'paid',
        notes TEXT,
        created_at TEXT NOT NULL,
        user_id TEXT NOT NULL,
        is_quick_sale INTEGER DEFAULT 0,
        cash_received REAL,
        profit_margin REAL,
        product_details TEXT,
        receipt_sms_sent INTEGER DEFAULT 0,
        sale_date TEXT,
        photo_url TEXT,
        customer_id TEXT,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        UNIQUE(sale_number, user_id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_sync ON sales(is_synced)');

    // Sale Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sync ON sale_items(is_synced)');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_queue_table ON sync_queue(table_name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at)');

    // Sync Metadata Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_pull_at TEXT,
        last_push_at TEXT,
        total_synced INTEGER DEFAULT 0,
        last_sync_status TEXT,
        last_error TEXT
      )
    ''');

    // App Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Local Notifications Table (OneSignal push notifications)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_notifications (
        notification_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        additional_data TEXT,
        received_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_local_notifications_received_at ON local_notifications(received_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_local_notifications_is_read ON local_notifications(is_read)');

    // Cashbox Transactions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cashbox_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_user_id ON cashbox_transactions(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_date ON cashbox_transactions(transaction_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_type ON cashbox_transactions(transaction_type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cashbox_sync ON cashbox_transactions(is_synced)');

    // Expense Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        name_bengali TEXT NOT NULL,
        description TEXT,
        description_bengali TEXT,
        icon_name TEXT NOT NULL,
        icon_color TEXT NOT NULL,
        bg_color TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON expense_categories(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expense_categories_is_system ON expense_categories(is_system)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expense_categories_sync ON expense_categories(is_synced)');

    // Expenses Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_sync ON expenses(is_synced)');

    // Purchases Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        purchase_number TEXT NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
        cash_given REAL,
        change_amount REAL,
        payment_status TEXT DEFAULT 'unpaid',
        payment_method TEXT,
        receipt_image_path TEXT,
        comment TEXT,
        sms_enabled INTEGER DEFAULT 0,
        receipt_number TEXT,
        subtotal REAL DEFAULT 0,
        delivery_charge REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        receipt_image_url TEXT,
        notes TEXT,
        purchase_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        UNIQUE(purchase_number, user_id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(purchase_date DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_sync ON purchases(is_synced)');

    // Purchase Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT,
        product_name TEXT NOT NULL,
        cost_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_cost REAL NOT NULL,
        unit_price REAL,
        total_price REAL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_synced_at TEXT,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON purchase_items(product_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchase_items_sync ON purchase_items(is_synced)');

    // Initialize default settings
    await db.insert(
      'app_settings',
      {'key': 'is_online', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      'app_settings',
      {'key': 'last_online_at', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      'app_settings',
      {'key': 'sync_enabled', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      'app_settings',
      {'key': 'sync_interval_minutes', 'value': '5'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert(
      'app_settings',
      {'key': 'current_user_id', 'value': ''},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('database_migrated') != true;
  }

  static Future<void> _migrateFromSupabase() async {
    try {
      // Check if Supabase is initialized
      if (!SupabaseConfig.isInitialized) {
        print(
            'Supabase not initialized yet - skipping first-run migration (will sync later)');
        return;
      }

      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('No user logged in - skipping migration');
        return;
      }

      print('Starting first-run migration from Supabase...');

      // Fetch all user data from Supabase
      final products =
          await supabase.from('products').select().eq('user_id', userId);

      final customers =
          await supabase.from('customers').select().eq('user_id', userId);

      final sales = await supabase.from('sales').select().eq('user_id', userId);

      final saleItems = await supabase.from('sale_items').select();

      final customerTransactions = await supabase
          .from('customer_transactions')
          .select()
          .eq('user_id', userId);

      final productGroups =
          await supabase.from('product_groups').select().eq('user_id', userId);

      final locations =
          await supabase.from('locations').select().eq('user_id', userId);

      final cashboxTransactions = await supabase
          .from('cashbox_transactions')
          .select()
          .eq('user_id', userId);

      // Fetch expense categories (system + user's categories)
      final expenseCategories = await supabase
          .from('expense_categories')
          .select()
          .or('is_system.eq.true,user_id.eq.$userId');

      // Fetch expenses
      final expenses =
          await supabase.from('expenses').select().eq('user_id', userId);

      // Fetch purchases
      final purchases =
          await supabase.from('purchases').select().eq('user_id', userId);

      // Fetch purchase items
      final purchaseItems = await supabase.from('purchase_items').select();

      // Insert into local database in a batch
      final batch = _database!.batch();

      // Products
      for (var product in products) {
        final productMap = Product.fromMap(product).toMap();
        productMap['user_id'] = userId;
        productMap['is_synced'] = 1;
        productMap['last_synced_at'] = DateTime.now().toIso8601String();
        productMap['created_at'] =
            productMap['created_at'] ?? DateTime.now().toIso8601String();
        productMap['updated_at'] =
            productMap['updated_at'] ?? DateTime.now().toIso8601String();
        batch.insert('products', productMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Customers
      for (var customer in customers) {
        final customerMap = Customer.fromMap(customer).toMap();
        customerMap['is_synced'] = 1;
        customerMap['last_synced_at'] = DateTime.now().toIso8601String();
        batch.insert('customers', customerMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Sales
      for (var sale in sales) {
        final saleMap = Sale.fromMap(sale).toJson();
        saleMap['user_id'] = userId;
        saleMap['is_synced'] = 1;
        saleMap['last_synced_at'] = DateTime.now().toIso8601String();
        batch.insert('sales', saleMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Sale Items
      for (var item in saleItems) {
        final itemMap = {
          'id': item['id'],
          'sale_id': item['sale_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'subtotal': item['subtotal'],
          'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('sale_items', itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Customer Transactions
      for (var transaction in customerTransactions) {
        final transactionMap = CustomerTransaction.fromMap(transaction).toMap();
        transactionMap['user_id'] = userId;
        transactionMap['is_synced'] = 1;
        transactionMap['last_synced_at'] = DateTime.now().toIso8601String();
        batch.insert('customer_transactions', transactionMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Product Groups
      for (var group in productGroups) {
        final groupMap = {
          'id': group['id'],
          'name': group['name'],
          'user_id': userId,
          'created_at': group['created_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('product_groups', groupMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Locations
      for (var location in locations) {
        final locationMap = {
          'id': location['id'],
          'name': location['name'],
          'user_id': userId,
          'created_at':
              location['created_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('locations', locationMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Cashbox Transactions
      for (var transaction in cashboxTransactions) {
        final transactionMap = {
          'id': transaction['id'],
          'user_id': userId,
          'transaction_type': transaction['transaction_type'],
          'amount': transaction['amount'],
          'description': transaction['description'] ?? '',
          'category': transaction['category'],
          'transaction_date': transaction['transaction_date'],
          'created_at':
              transaction['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at':
              transaction['updated_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('cashbox_transactions', transactionMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Expense Categories
      for (var category in expenseCategories) {
        final categoryMap = {
          'id': category['id'],
          'user_id': category['user_id'], // Can be null for system categories
          'name': category['name'],
          'name_bengali': category['name_bengali'],
          'description': category['description'],
          'description_bengali': category['description_bengali'],
          'icon_name': category['icon_name'],
          'icon_color': category['icon_color'],
          'bg_color': category['bg_color'],
          'is_system': category['is_system'] == true ? 1 : 0,
          'created_at':
              category['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at':
              category['updated_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('expense_categories', categoryMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Expenses
      for (var expense in expenses) {
        final expenseMap = {
          'id': expense['id'],
          'user_id': userId,
          'category_id': expense['category_id'],
          'amount': expense['amount'],
          'description': expense['description'],
          'expense_date': expense['expense_date'],
          'created_at':
              expense['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at':
              expense['updated_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('expenses', expenseMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Purchases
      for (var purchase in purchases) {
        final purchaseMap = {
          'id': purchase['id'],
          'user_id': userId,
          'purchase_number': purchase['purchase_number'],
          'supplier_id': purchase['supplier_id'],
          'supplier_name': purchase['supplier_name'],
          'total_amount': purchase['total_amount'],
          'payment_status': purchase['payment_status'] ?? 'unpaid',
          'payment_method': purchase['payment_method'],
          'notes': purchase['notes'],
          'purchase_date': purchase['purchase_date'],
          'created_at':
              purchase['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at':
              purchase['updated_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('purchases', purchaseMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Purchase Items
      for (var item in purchaseItems) {
        final itemMap = {
          'id': item['id'],
          'purchase_id': item['purchase_id'],
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'cost_price': item['cost_price'],
          'quantity': item['quantity'],
          'total_cost': item['total_cost'],
          'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'last_synced_at': DateTime.now().toIso8601String(),
        };
        batch.insert('purchase_items', itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      // Mark migration as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_migrated', true);

      print('Migration completed successfully!');
      print(
          'Migrated: ${products.length} products, ${customers.length} customers, ${sales.length} sales, ${purchases.length} purchases, ${cashboxTransactions.length} cashbox transactions, ${expenseCategories.length} expense categories, ${expenses.length} expenses');
    } catch (e) {
      print('Migration failed: $e');
      // Don't throw - allow app to continue without migration
    }
  }

  static Database get database {
    if (_database == null) {
      throw Exception(
          'Database not initialized. Call DatabaseConfig.initialize() first.');
    }
    return _database!;
  }

  static Future<void> clearUserData() async {
    if (_database == null) return;

    await _database!.delete('products');
    await _database!.delete('customers');
    await _database!.delete('customer_transactions');
    await _database!.delete('sales');
    await _database!.delete('sale_items');
    await _database!.delete('purchases');
    await _database!.delete('purchase_items');
    await _database!.delete('sync_queue');
    await _database!.delete('sync_metadata');
    await _database!.delete('product_groups');
    await _database!.delete('locations');
    await _database!.delete('cashbox_transactions');
    await _database!.delete('expense_categories');
    await _database!.delete('expenses');

    // Reset migration flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('database_migrated', false);

    print('User data cleared from local database');
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/employee.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Safe fallback for Chrome/Edge web environment
    if (_database != null) return _database!;
    try {
      _database = await _initDB('smart_khata_local.db');
      return _database;
    } catch (e) {
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Catalogue Tables
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        urdu_name TEXT,
        category TEXT,
        unit TEXT,
        buying_price REAL,
        selling_price REAL,
        current_stock REAL,
        low_stock_threshold REAL,
        supplier_id TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        total_purchased REAL,
        total_paid REAL,
        balance_owed REAL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        type TEXT,
        balance_due REAL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role_title TEXT,
        salary_type TEXT,
        salary_rate REAL,
        phone TEXT,
        active INTEGER,
        user_account_id TEXT,
        updated_at TEXT
      )
    ''');

    // Pending Write Queues
    await db.execute('''
      CREATE TABLE pending_orders (
        client_id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // Save/Overwrite Catalogue Data (Server Wins)
  Future<void> saveProducts(List<Product> products) async {
    final db = await instance.database;
    if (db == null) return;
    final batch = db.batch();
    for (var p in products) {
      batch.insert('products', p.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await instance.database;
    if (db == null) return [];
    final maps = await db.query('products');
    return maps.map((m) => Product.fromJson(m)).toList();
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final db = await instance.database;
    if (db == null) return;
    final batch = db.batch();
    for (var c in customers) {
      batch.insert('customers', c.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Customer>> getCachedCustomers() async {
    final db = await instance.database;
    if (db == null) return [];
    final maps = await db.query('customers');
    return maps.map((m) => Customer.fromJson(m)).toList();
  }

  // Pending Queue Methods
  Future<void> queueOfflineOrder(String clientId, String jsonPayload) async {
    final db = await instance.database;
    if (db == null) return;
    await db.insert('pending_orders', {
      'client_id': clientId,
      'payload_json': jsonPayload,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('pending_orders');
  }

  Future<void> removePendingOrder(String clientId) async {
    final db = await instance.database;
    if (db == null) return;
    await db.delete('pending_orders', where: 'client_id = ?', whereArgs: [clientId]);
  }

  Future<void> queueOfflineAttendance(String employeeId, String date, String status) async {
    final db = await instance.database;
    if (db == null) return;
    await db.insert('pending_attendance', {
      'employee_id': employeeId,
      'date': date,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('pending_attendance');
  }

  Future<void> clearPendingAttendance() async {
    final db = await instance.database;
    if (db == null) return;
    await db.delete('pending_attendance');
  }
}

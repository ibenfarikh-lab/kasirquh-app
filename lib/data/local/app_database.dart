import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database SQLite lokal — offline-first. Tulis lokal dulu,
/// sinkron ke Firestore via [SyncEngine] saat online.
class AppDatabase {
  static const _name = 'kasirquh.db';
  static const _version = 4;
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, _name),
      version: _version,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
            price INTEGER NOT NULL, cost INTEGER NOT NULL DEFAULT 0,
            stock INTEGER NOT NULL DEFAULT 0, lowStockAt INTEGER NOT NULL DEFAULT 5,
            barcode TEXT,
            photoPath TEXT, active INTEGER NOT NULL DEFAULT 1,
            updatedAt INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE orders(
            id TEXT PRIMARY KEY, customerId TEXT NOT NULL,
            customerName TEXT NOT NULL, items TEXT NOT NULL,
            total INTEGER NOT NULL, status TEXT NOT NULL,
            payment TEXT NOT NULL, createdAt INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE customers(
            uid TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL,
            approvalStatus TEXT NOT NULL DEFAULT 'pending',
            coins INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL)''');
        await db.execute('''
          CREATE TABLE journal(
            id TEXT PRIMARY KEY, kind TEXT NOT NULL, label TEXT NOT NULL,
            amount INTEGER NOT NULL, refId TEXT,
            createdAt INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE coin_ledger(
            id TEXT PRIMARY KEY, customerId TEXT NOT NULL,
            delta INTEGER NOT NULL, reason TEXT NOT NULL,
            createdAt INTEGER NOT NULL, synced INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE chat_threads(
            id TEXT PRIMARY KEY, customerId TEXT NOT NULL,
            customerName TEXT NOT NULL, unread INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY, threadId TEXT NOT NULL,
            senderId TEXT NOT NULL, senderRole TEXT NOT NULL DEFAULT 'customer',
            text TEXT NOT NULL,
            createdAt INTEGER NOT NULL, synced INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE rumpi_posts(
            id TEXT PRIMARY KEY, authorId TEXT NOT NULL,
            authorName TEXT NOT NULL, text TEXT NOT NULL,
            likes INTEGER NOT NULL DEFAULT 0, isSeed INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL)''');
        await db.execute('''
          CREATE TABLE store_settings(
            key TEXT PRIMARY KEY, value TEXT NOT NULL,
            updatedAt INTEGER NOT NULL DEFAULT 0)''');
        // Antrean sinkron: operasi tulis yang belum terkirim ke Firestore.
        await db.execute('''
          CREATE TABLE sync_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection TEXT NOT NULL, docId TEXT NOT NULL,
            op TEXT NOT NULL, payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL)''');
        await _createStockNotes(db);
        await _createStoreNotes(db);
        await _createPromos(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await _createStockNotes(db);
        }
        if (oldVersion < 3) {
          await _createStoreNotes(db);
        }
        if (oldVersion < 4) {
          await _createPromos(db);
          // Kolom baru v4: batas menipis per produk + peran pengirim pesan.
          try {
            await db.execute(
                'ALTER TABLE products ADD COLUMN lowStockAt INTEGER NOT NULL DEFAULT 5');
          } catch (_) {}
          try {
            await db.execute(
                "ALTER TABLE messages ADD COLUMN senderRole TEXT NOT NULL DEFAULT 'customer'");
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE journal ADD COLUMN refId TEXT');
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createPromos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promos(
        id TEXT PRIMARY KEY, title TEXT NOT NULL, subtitle TEXT,
        productId TEXT, discountType TEXT, discountValue INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        startsAt INTEGER, endsAt INTEGER,
        updatedAt INTEGER NOT NULL DEFAULT 0)''');
  }

  static Future<void> _createStockNotes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_notes(
        id TEXT PRIMARY KEY, date TEXT NOT NULL, supplier TEXT NOT NULL,
        items TEXT NOT NULL, total INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        createdAt INTEGER NOT NULL, synced INTEGER NOT NULL DEFAULT 0)''');
  }

  /// Tutup (untuk tes).
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Catatan Toko — lokal saja (tidak ada koleksi Firestore/rules untuknya).
  static Future<void> _createStoreNotes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_notes(
        id TEXT PRIMARY KEY, title TEXT NOT NULL,
        body TEXT NOT NULL, createdAt INTEGER NOT NULL)''');
  }
}

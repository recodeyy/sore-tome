import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Local read cache for "instant" screen loads. Strictly best-effort:
/// every public method fails soft (empty result / no-op) because a cache
/// failure must never break a screen. Providers call these from their
/// constructors, so an uncaught throw here crashes the whole widget tree
/// (the release-build "blank screen after login" bug).
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sero_cache.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) => _ensureTables(db),
      // Existing installs created v1 before the events table existed (and a
      // schema that may predate other tables). onUpgrade repairs them.
      onUpgrade: (db, oldVersion, newVersion) => _ensureTables(db),
    );
  }

  /// Idempotent schema: safe to run on both fresh and existing databases.
  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notices(
        id TEXT PRIMARY KEY,
        title TEXT,
        body TEXT,
        createdAt TEXT,
        society_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS issues(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        status TEXT,
        priority TEXT,
        postedBy TEXT,
        society_id TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        type TEXT,
        category TEXT,
        date TEXT,
        society_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS events(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        date TEXT,
        location TEXT,
        society_id TEXT,
        createdAt TEXT
      )
    ''');
  }

  // Generic Save — best-effort.
  Future<void> saveItems(String table, List<Map<String, dynamic>> items) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (var item in items) {
        batch.insert(
          table,
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      debugPrint('✅ LocalDB: Saved ${items.length} items to $table');
    } catch (e) {
      debugPrint('LocalDB: save to $table skipped ($e)');
    }
  }

  // Generic Fetch — best-effort; a cache miss and a cache failure look the same.
  Future<List<Map<String, dynamic>>> getItems(String table, {String? societyId}) async {
    try {
      final db = await database;
      if (societyId != null) {
        return await db.query(table, where: 'society_id = ?', whereArgs: [societyId]);
      }
      return await db.query(table);
    } catch (e) {
      debugPrint('LocalDB: read from $table skipped ($e)');
      return const [];
    }
  }

  // Generic Clear — best-effort.
  Future<void> clearTable(String table) async {
    try {
      final db = await database;
      await db.delete(table);
    } catch (e) {
      debugPrint('LocalDB: clear of $table skipped ($e)');
    }
  }
}

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Notices Table
    await db.execute('''
      CREATE TABLE notices(
        id TEXT PRIMARY KEY,
        title TEXT,
        body TEXT,
        createdAt TEXT,
        society_id TEXT
      )
    ''');

    // 2. Issues Table
    await db.execute('''
      CREATE TABLE issues(
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

    // 3. Transactions Table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        type TEXT,
        category TEXT,
        date TEXT,
        society_id TEXT
      )
    ''');
  }

  // Generic Save
  Future<void> saveItems(String table, List<Map<String, dynamic>> items) async {
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
  }

  // Generic Fetch
  Future<List<Map<String, dynamic>>> getItems(String table, {String? societyId}) async {
    final db = await database;
    if (societyId != null) {
      return await db.query(table, where: 'society_id = ?', whereArgs: [societyId]);
    }
    return await db.query(table);
  }

  // Generic Clear
  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sero/providers/shared/channels_provider.dart';

/// Local chat outbox/cache. Best-effort like LocalDatabaseService: a cache
/// failure (e.g. sqflite unavailable on web) must never crash a screen.
class OfflineRepository {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sero_chat.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId TEXT UNIQUE,
            channelId TEXT,
            status TEXT,
            data TEXT,
            createdAt INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> saveMessage(ChatMessage message, String channelId, {required MessageStatus status}) async {
    try {
      final db = await database;
      await db.insert(
        'local_messages',
        {
          'clientId': message.clientId,
          'channelId': channelId,
          'status': status.name,
          'data': jsonEncode(message.toMap()),
          'createdAt': message.createdAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (status == MessageStatus.sent || status == MessageStatus.delivered) {
        await _cleanupOldMessages(channelId);
      }
    } catch (e) {
      debugPrint('OfflineRepo: saveMessage skipped ($e)');
    }
  }

  static Future<void> markAsSynced(String clientId) async {
    try {
      final db = await database;
      await db.update(
        'local_messages',
        {'status': MessageStatus.sent.name},
        where: 'clientId = ?',
        whereArgs: [clientId],
      );
    } catch (e) {
      debugPrint('OfflineRepo: markAsSynced skipped ($e)');
    }
  }

  static Future<List<ChatMessage>> getPendingMessages(String channelId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'local_messages',
        where: 'channelId = ? AND (status = ? OR status = ?)',
        whereArgs: [channelId, MessageStatus.sending.name, MessageStatus.error.name],
        orderBy: 'createdAt ASC',
      );

      return List.generate(maps.length, (i) {
        final data = jsonDecode(maps[i]['data']);
        return ChatMessage.fromMap(data, maps[i]['clientId'] ?? 'local_${maps[i]['id']}').copyWith(
          status: MessageStatus.values.firstWhere((e) => e.name == maps[i]['status']),
        );
      });
    } catch (e) {
      debugPrint('OfflineRepo: getPendingMessages skipped ($e)');
      return const [];
    }
  }

  static Future<List<ChatMessage>> getCachedMessages(String channelId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'local_messages',
        where: 'channelId = ? AND status = ?',
        whereArgs: [channelId, MessageStatus.sent.name],
        orderBy: 'createdAt DESC',
        limit: 200,
      );

      return List.generate(maps.length, (i) {
        final data = jsonDecode(maps[i]['data']);
        return ChatMessage.fromMap(data, maps[i]['clientId'] ?? 'local_${maps[i]['id']}').copyWith(
          status: MessageStatus.sent,
        );
      });
    } catch (e) {
      debugPrint('OfflineRepo: getCachedMessages skipped ($e)');
      return const [];
    }
  }

  static Future<void> _cleanupOldMessages(String channelId) async {
    final db = await database;
    
    // Safety Hardening: Keep last 150 SYNCED messages per chat.
    // We NEVER delete messages with status 'sending', 'error', or 'uploading'.
    final List<Map<String, dynamic>> last150 = await db.query(
      'local_messages',
      columns: ['createdAt'],
      where: 'channelId = ? AND status = ?',
      whereArgs: [channelId, MessageStatus.sent.name],
      orderBy: 'createdAt DESC',
      limit: 1,
      offset: 149, // Retention cap
    );

    if (last150.isNotEmpty) {
      final cutoff = last150[0]['createdAt'];
      await db.delete(
        'local_messages',
        where: 'channelId = ? AND status = ? AND createdAt < ?',
        whereArgs: [channelId, MessageStatus.sent.name, cutoff],
      );
    }
  }

  static Future<void> deleteMessage(String clientId) async {
    try {
      final db = await database;
      await db.delete(
        'local_messages',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );
    } catch (e) {
      debugPrint('OfflineRepo: deleteMessage skipped ($e)');
    }
  }
}



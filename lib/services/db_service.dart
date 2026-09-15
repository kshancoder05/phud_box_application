import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/batch.dart';

class DBService {
  static final DBService instance = DBService._internal();

  DBService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'phud_box.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE batch_logs (
            id TEXT PRIMARY KEY,
            color TEXT,
            date TEXT,
            result TEXT,
            instruments TEXT,
            time TEXT,
            uvIntensity TEXT,
            expiry TEXT,
            error TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertLog(BatchLog log) async {
    final db = await database;
    await db.insert(
      'batch_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BatchLog>> getLogs() async {
    final db = await database;
    final maps = await db.query('batch_logs', orderBy: 'date DESC, time DESC');
    return maps.map(BatchLog.fromMap).toList();
  }

  Future<void> deleteLog(String id) async {
    final db = await database;
    await db.delete('batch_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('batch_logs');
  }
}

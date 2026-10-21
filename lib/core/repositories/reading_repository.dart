import 'package:sqflite/sqflite.dart' show Sqflite;

import '../database/database_helper.dart';
import '../models/reading.dart';

/// Repository for blood pressure reading CRUD and queries.
class ReadingRepository {
  ReadingRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _table = 'readings';

  Future<void> insert(Reading reading) async {
    final db = await _dbHelper.database;
    await db.insert(_table, reading.toMap());
  }

  Future<void> update(Reading reading) async {
    final db = await _dbHelper.database;
    await db.update(
      _table,
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<Reading?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Reading.fromMap(maps.first);
  }

  Future<Reading?> getLatest(String profileId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Reading.fromMap(maps.first);
  }

  Future<List<Reading>> getAll({
    required String profileId,
    int? limit,
    int? offset,
    bool newestFirst = true,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp ${newestFirst ? 'DESC' : 'ASC'}',
      limit: limit,
      offset: offset,
    );
    return maps.map(Reading.fromMap).toList();
  }

  Future<List<Reading>> getByDateRange({
    required String profileId,
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'profileId = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        profileId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );
    return maps.map(Reading.fromMap).toList();
  }

  Future<List<Reading>> search({
    required String profileId,
    String? query,
    int? minSystolic,
    int? maxSystolic,
    int? minDiastolic,
    int? maxDiastolic,
    int? minPulse,
    int? maxPulse,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    final conditions = <String>['profileId = ?'];
    final args = <dynamic>[profileId];

    if (minSystolic != null) {
      conditions.add('systolic >= ?');
      args.add(minSystolic);
    }
    if (maxSystolic != null) {
      conditions.add('systolic <= ?');
      args.add(maxSystolic);
    }
    if (minDiastolic != null) {
      conditions.add('diastolic >= ?');
      args.add(minDiastolic);
    }
    if (maxDiastolic != null) {
      conditions.add('diastolic <= ?');
      args.add(maxDiastolic);
    }
    if (minPulse != null) {
      conditions.add('pulse >= ?');
      args.add(minPulse);
    }
    if (maxPulse != null) {
      conditions.add('pulse <= ?');
      args.add(maxPulse);
    }
    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      conditions.add('timestamp <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }
    if (query != null && query.isNotEmpty) {
      conditions.add('(notes LIKE ? OR symptoms LIKE ? OR mood LIKE ?)');
      final like = '%$query%';
      args.addAll([like, like, like]);
    }

    final maps = await db.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'timestamp DESC',
    );
    return maps.map(Reading.fromMap).toList();
  }

  Future<int> count(String profileId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE profileId = ?',
      [profileId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

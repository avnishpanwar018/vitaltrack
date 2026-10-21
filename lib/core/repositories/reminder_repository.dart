import '../database/database_helper.dart';
import '../models/reminder.dart';

/// Repository for reminder CRUD operations.
class ReminderRepository {
  ReminderRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _table = 'reminders';

  Future<void> insert(Reminder reminder) async {
    final db = await _dbHelper.database;
    await db.insert(_table, reminder.toMap());
  }

  Future<void> update(Reminder reminder) async {
    final db = await _dbHelper.database;
    await db.update(
      _table,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(_table, orderBy: 'time ASC');
    return maps.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getEnabled() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'time ASC',
    );
    return maps.map(Reminder.fromMap).toList();
  }
}

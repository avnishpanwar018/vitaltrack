import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/profile.dart';

/// Repository for family profile management.
class ProfileRepository {
  ProfileRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _table = 'profiles';
  static const _uuid = Uuid();

  Future<void> insert(Profile profile) async {
    final db = await _dbHelper.database;
    if (profile.isDefault) {
      await _clearDefault(db);
    }
    await db.insert(_table, profile.toMap());
  }

  Future<void> update(Profile profile) async {
    final db = await _dbHelper.database;
    if (profile.isDefault) {
      await _clearDefault(db);
    }
    await db.update(
      _table,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Profile>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(_table, orderBy: 'isDefault DESC, name ASC');
    return maps.map(Profile.fromMap).toList();
  }

  Future<Profile?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  Future<Profile?> getDefault() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isNotEmpty) return Profile.fromMap(maps.first);

    final all = await getAll();
    return all.isNotEmpty ? all.first : null;
  }

  /// Creates default profile if none exists.
  Future<Profile> ensureDefaultProfile() async {
    final existing = await getDefault();
    if (existing != null) return existing;

    final profile = Profile(
      id: _uuid.v4(),
      name: 'Me',
      relationship: 'Self',
      isDefault: true,
    );
    await insert(profile);
    return profile;
  }

  Future<void> setDefault(String id) async {
    final db = await _dbHelper.database;
    await _clearDefault(db);
    await db.update(
      _table,
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _clearDefault(dynamic db) async {
    await db.update(_table, {'isDefault': 0});
  }
}

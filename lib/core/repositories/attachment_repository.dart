import '../database/database_helper.dart';
import '../models/attachment.dart';

/// Repository for file attachment management.
class AttachmentRepository {
  AttachmentRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _table = 'attachments';

  Future<void> insert(Attachment attachment) async {
    final db = await _dbHelper.database;
    await db.insert(_table, attachment.toMap());
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Attachment>> getByProfile(String profileId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _table,
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp DESC',
    );
    return maps.map(Attachment.fromMap).toList();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

/// SQLite database helper — offline-first local storage.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;
  String? dbPathOverride;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (dbPathOverride != null) {
      path = dbPathOverride!;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, AppConstants.databaseName);
    }

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        relationship TEXT DEFAULT 'Self',
        photoPath TEXT,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE readings (
        id TEXT PRIMARY KEY,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER NOT NULL,
        weight REAL,
        notes TEXT,
        medicationTaken INTEGER DEFAULT 0,
        symptoms TEXT,
        mood TEXT,
        timestamp INTEGER NOT NULL,
        profileId TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        profileId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        filePath TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileType TEXT NOT NULL,
        description TEXT,
        timestamp INTEGER NOT NULL,
        profileId TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_readings_profile ON readings(profileId)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_timestamp ON readings(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_attachments_profile ON attachments(profileId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

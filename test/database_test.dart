import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vitaltrack/core/database/database_helper.dart';
import 'package:vitaltrack/core/models/profile.dart';
import 'package:vitaltrack/core/models/reading.dart';
import 'package:vitaltrack/core/repositories/profile_repository.dart';
import 'package:vitaltrack/core/repositories/reading_repository.dart';

void main() {
  // Initialize sqflite FFI for local tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SQLite Database Schema & Operations Tests', () {
    late DatabaseHelper dbHelper;
    late ProfileRepository profileRepo;
    late ReadingRepository readingRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbPathOverride = inMemoryDatabasePath;
      
      profileRepo = ProfileRepository(dbHelper);
      readingRepo = ReadingRepository(dbHelper);
      
      // Open / Initialize
      await dbHelper.database;
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Insert and query family profiles', () async {
      const profile = Profile(
        id: 'test-profile-1',
        name: 'Avnish',
        age: 21,
        gender: 'Male',
        relationship: 'Self',
        isDefault: true,
      );

      await profileRepo.insert(profile);

      final retrieved = await profileRepo.getById('test-profile-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Avnish');
      expect(retrieved.age, 21);
      expect(retrieved.isDefault, isTrue);

      final all = await profileRepo.getAll();
      expect(all.length, 1);
    });

    test('Insert and query blood pressure readings', () async {
      const profile = Profile(
        id: 'test-profile-2',
        name: 'Jane Doe',
        age: 30,
        relationship: 'Spouse',
      );
      await profileRepo.insert(profile);

      final reading = Reading(
        id: 'test-reading-1',
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        timestamp: DateTime.now(),
        profileId: 'test-profile-2',
        notes: 'Feeling good',
        medicationTaken: true,
        mood: 'Good',
        symptoms: const ['None'],
      );

      await readingRepo.insert(reading);

      final latest = await readingRepo.getLatest('test-profile-2');
      expect(latest, isNotNull);
      expect(latest!.systolic, 120);
      expect(latest.diastolic, 80);
      expect(latest.notes, 'Feeling good');

      final count = await readingRepo.count('test-profile-2');
      expect(count, 1);
    });

    test('Cascade deletes readings when a profile is deleted', () async {
      const profile = Profile(
        id: 'test-profile-3',
        name: 'Delete Target',
        relationship: 'Other',
      );
      await profileRepo.insert(profile);

      final reading = Reading(
        id: 'test-reading-2',
        systolic: 130,
        diastolic: 85,
        pulse: 80,
        timestamp: DateTime.now(),
        profileId: 'test-profile-3',
      );
      await readingRepo.insert(reading);

      // Verify insertion
      expect(await readingRepo.count('test-profile-3'), 1);

      // Delete profile
      await profileRepo.delete('test-profile-3');

      // Verify profile is deleted
      expect(await profileRepo.getById('test-profile-3'), isNull);

      // Verify reading is cascade-deleted (using raw query since repo helper requires profile ID)
      final db = await dbHelper.database;
      final remaining = await db.query('readings', where: 'id = ?', whereArgs: ['test-reading-2']);
      expect(remaining, isEmpty);
    });
  });
}

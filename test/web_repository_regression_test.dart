import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitaltrack/core/models/attachment.dart';
import 'package:vitaltrack/core/models/profile.dart';
import 'package:vitaltrack/core/models/reading.dart';
import 'package:vitaltrack/core/repositories/in_memory_data_store.dart';
import 'package:vitaltrack/core/repositories/in_memory_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('web repositories persist data and cascade profile deletion', () async {
    final store = InMemoryDataStore(preferences: SharedPreferences.getInstance());
    final profiles = InMemoryProfileRepository(store);
    final readings = InMemoryReadingRepository(store);
    final attachments = InMemoryAttachmentRepository(store);
    const profile = Profile(
      id: 'web-profile',
      name: 'Web User',
      relationship: 'Self',
      isDefault: true,
    );
    final timestamp = DateTime(2026, 10, 14, 9, 30);

    await profiles.insert(profile);
    await readings.insert(Reading(
      id: 'web-reading',
      systolic: 120,
      diastolic: 80,
      pulse: 72,
      timestamp: timestamp,
      profileId: profile.id,
    ));
    await attachments.insert(Attachment(
      id: 'web-attachment',
      filePath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      fileType: 'pdf',
      timestamp: timestamp,
      profileId: profile.id,
    ));

    final reloadedStore =
        InMemoryDataStore(preferences: SharedPreferences.getInstance());
    final reloadedProfiles = InMemoryProfileRepository(reloadedStore);
    final reloadedReadings = InMemoryReadingRepository(reloadedStore);
    final reloadedAttachments = InMemoryAttachmentRepository(reloadedStore);

    expect(await reloadedProfiles.getById(profile.id), profile);
    expect(await reloadedReadings.getById('web-reading'), isNotNull);
    expect(await reloadedAttachments.getByProfile(profile.id), hasLength(1));

    await reloadedProfiles.delete(profile.id);

    expect(await reloadedProfiles.getById(profile.id), isNull);
    expect(await reloadedReadings.count(profile.id), 0);
    expect(await reloadedAttachments.getByProfile(profile.id), isEmpty);
  });

  test('web date filters include both boundary timestamps', () async {
    final store = InMemoryDataStore(preferences: SharedPreferences.getInstance());
    final repository = InMemoryReadingRepository(store);
    const profileId = 'boundary-profile';
    final start = DateTime(2026, 10, 14, 8);
    final end = DateTime(2026, 10, 14, 10);

    for (final entry in [
      ('start-reading', start),
      ('middle-reading', DateTime(2026, 10, 14, 9)),
      ('end-reading', end),
    ]) {
      await repository.insert(Reading(
        id: entry.$1,
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        timestamp: entry.$2,
        profileId: profileId,
      ));
    }

    final result = await repository.getByDateRange(
      profileId: profileId,
      start: start,
      end: end,
    );

    expect(result.map((reading) => reading.id), [
      'start-reading',
      'middle-reading',
      'end-reading',
    ]);
  });
}

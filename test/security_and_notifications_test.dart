import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitaltrack/core/models/reminder.dart';
import 'package:vitaltrack/core/services/encryption_service.dart';
import 'package:vitaltrack/core/services/notification_service.dart';
import 'package:vitaltrack/core/services/security_service.dart';
import 'package:vitaltrack/core/services/settings_service.dart';

void main() {
  group('PIN security services', () {
    late EncryptionService encryption;
    late SecurityService security;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      encryption = EncryptionService(storage: const FlutterSecureStorage());
      security = SecurityService(encryption);
    });

    test('rejects empty, non-digit, and wrong-length PINs at storage layer', () async {
      for (final pin in ['', '12a4', '123']) {
        await expectLater(
          encryption.setPin(pin),
          throwsA(isA<PinException>()),
        );
      }
      expect(await encryption.getPin(), isNull);
    });

    test('requires confirmation and current PIN for protected changes', () async {
      await security.setPin('1234', confirmation: '1234');

      await expectLater(
        security.setPin('5678', confirmation: '5670', currentPin: '1234'),
        throwsA(isA<PinException>()),
      );
      await expectLater(
        security.setPin('5678', confirmation: '5678', currentPin: '0000'),
        throwsA(isA<PinException>()),
      );
      expect(await security.verifyPin('1234'), isTrue);
      expect(await security.verifyPin('5678'), isFalse);
    });

    test('requires the current PIN before disabling', () async {
      await encryption.setPin('2468');

      await expectLater(
        encryption.deletePin(currentPin: '0000'),
        throwsA(isA<PinException>()),
      );
      expect(await encryption.getPin(), '2468');

      await encryption.deletePin(currentPin: '2468');
      expect(await encryption.getPin(), isNull);
    });
  });

  group('settings security and reminder opt-in', () {
    test('PIN lock and reminder opt-in defaults are safe', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());

      expect(settings.remindersOptedIn, isFalse);
      await settings.setPinEnabled(true);
      await settings.setPinEnabled(false);
      expect(settings.pinEnabled, isFalse);
    });
  });

  group('notification safety', () {
    test('uses stable deterministic IDs instead of runtime string hashes', () {
      final first = NotificationService.notificationIdFor('reminder-a');
      final second = NotificationService.notificationIdFor('reminder-a');
      final different = NotificationService.notificationIdFor('reminder-b');

      expect(first, greaterThan(0));
      expect(first, second);
      expect(first, isNot(different));
    });

    test('unsupported platforms do not attempt notification work', () async {
      final service = NotificationService();
      const reminder = Reminder(
        id: 'unsupported-platform-reminder',
        title: 'Reminder',
        time: '08:00',
      );

      await service.initialize();
      expect(await service.requestPermissions(), isFalse);
      await service.scheduleReminder(reminder);
      await service.cancelReminder(reminder.id);
      await service.cancelAll();
    });
  });
}

/// Future-ready Firebase sync service stub.
///
/// Version 2 will implement:
/// - Firebase Authentication
/// - Cloud Firestore sync
/// - Automatic backup
/// - Multi-device sync
abstract class CloudSyncService {
  Future<bool> isSignedIn();
  Future<void> signIn();
  Future<void> signOut();
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
}

class CloudSyncStub implements CloudSyncService {
  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<void> signIn() async {
    throw UnimplementedError('Cloud sync available in Version 2');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> syncToCloud() async {}

  @override
  Future<void> syncFromCloud() async {}
}

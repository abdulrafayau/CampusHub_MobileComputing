import 'package:flutter_test/flutter_test.dart';
import 'package:loopair/data/app_store.dart';
import 'package:loopair/data/models.dart';
import 'package:loopair/services/location_service.dart';
import 'package:loopair/services/security.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Inside the Main Auditorium geofence.
const atVenue = GeoStamp(lat: 33.71372, lng: 73.02560, accuracy: 10);

Future<AppStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppStore();
  await s.load();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login works, wrong password fails, deactivated is refused', () async {
    final s = await freshStore();
    expect(await s.login('student@au.edu.pk', 'nope'), isNotNull);
    expect(s.currentUser, isNull);
    expect(await s.login('STUDENT@au.edu.pk', 'student123'), isNull);
    expect(s.currentUser?.id, 'u_s1');
    await s.logout();
    s.userById('u_s3')!.active = false;
    expect(await s.login('usman@au.edu.pk', 'student123'), contains('deactivated'));
  });

  test('lockout survives an app restart', () async {
    final s = await freshStore();
    for (var i = 0; i < 5; i++) {
      await s.login('student@au.edu.pk', 'wrong');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final restarted = AppStore();
    await restarted.load();
    expect(await restarted.login('student@au.edu.pk', 'student123'), contains('Too many attempts'));
  });

  test('QR check-in needs a current token', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    final e = s.eventById('e_seerah')!;
    expect(s.checkIn(e, CheckMethod.qr, atVenue).ok, isFalse);
    expect(s.checkIn(e, CheckMethod.qr, atVenue, token: '000000').ok,
        CheckInToken.current(e) == '000000');
    final r = s.checkIn(e, CheckMethod.qr, atVenue, token: CheckInToken.current(e));
    expect(r.ok, isTrue);
    expect(r.record!.status, AttendanceStatus.recorded);
  });

  test('in-app check-in without location waits for verification', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    final r = s.checkIn(s.eventById('e_seerah')!, CheckMethod.app, const GeoStamp());
    expect(r.ok, isTrue);
    expect(r.record!.status, AttendanceStatus.pending);
    expect(r.record!.flags, contains('No location'));
  });

  test('in-app check-in at the venue is recorded directly', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    final r = s.checkIn(s.eventById('e_seerah')!, CheckMethod.app, atVenue);
    expect(r.record!.status, AttendanceStatus.recorded);
    expect(r.record!.flags, isEmpty);
  });

  test('cannot be checked in to two events at once', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    s.checkIn(s.eventById('e_seerah')!, CheckMethod.app, atVenue);
    final second = s.checkIn(s.eventById('e_aucis_meet')!, CheckMethod.marked, atVenue);
    expect(second.ok, isFalse);
    expect(second.message, contains('Leave'));
  });

  test('self-marking only works for meetings', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    expect(s.checkIn(s.eventById('e_seerah')!, CheckMethod.marked, atVenue).ok, isFalse);
  });

  test('leave stamps check-out and blocks a second check-in', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    final e = s.eventById('e_seerah')!;
    final rec = s.checkIn(e, CheckMethod.app, atVenue).record!;
    expect(s.checkOut(rec, atVenue).ok, isTrue);
    expect(rec.checkOutAt, isNotNull);
    expect(s.checkIn(e, CheckMethod.app, atVenue).ok, isFalse);
  });

  test('registration respects capacity and cancellation', () async {
    final s = await freshStore();
    await s.login('student@au.edu.pk', 'student123');
    final e = s.eventById('e_flutter')!..capacity = 3; // already 3 registered incl. u_s1
    e.registeredIds.remove('u_s1');
    e.registeredIds.add('u_s9');
    expect(s.toggleRegistration(e), contains('full'));
    e.capacity = 0;
    e.status = EventStatus.cancelled;
    expect(s.toggleRegistration(e), contains('cancelled'));
  });

  test('students cannot verify, wrong faculty cannot verify', () async {
    final s = await freshStore();
    final pending = s.attendance.firstWhere((r) => r.status == AttendanceStatus.pending);
    await s.login('student@au.edu.pk', 'student123');
    expect(() => s.review(pending, true), throwsA(isA<PermissionDenied>()));
    await s.logout();
    await s.login('imran.haider@au.edu.pk', 'faculty123'); // GDGoC, not AUCIS
    expect(() => s.review(pending, true), throwsA(isA<PermissionDenied>()));
    await s.logout();
    await s.login('faculty@au.edu.pk', 'faculty123'); // AUCIS focal
    s.review(pending, true);
    expect(pending.status, AttendanceStatus.verified);
  });

  test('only admin can delete users; admin cannot delete self', () async {
    final s = await freshStore();
    await s.login('faculty@au.edu.pk', 'faculty123');
    expect(() => s.deleteUser(s.userById('u_s2')!), throwsA(isA<PermissionDenied>()));
    await s.logout();
    await s.login('dev@loopair.app', 'admin123');
    expect(() => s.deleteUser(s.currentUser!), throwsA(isA<PermissionDenied>()));
    s.deleteUser(s.userById('u_s2')!);
    expect(s.userById('u_s2'), isNull);
    expect(s.attendance.any((r) => r.userId == 'u_s2'), isFalse);
  });

  test('student sign-up enforces domain, policy and uniqueness', () async {
    final s = await freshStore();
    expect(
        await s.register(
            name: 'Test User', email: 'x@gmail.com', regNo: '239999', department: 'BBA', password: 'GoodPass1'),
        contains('Air University'));
    expect(
        await s.register(
            name: 'Test User', email: 'x@au.edu.pk', regNo: '221034', department: 'BBA', password: 'GoodPass1'),
        contains('registration number'));
    expect(
        await s.register(
            name: 'Test User', email: 'x@au.edu.pk', regNo: '239999', department: 'BBA', password: 'weak'),
        contains('requirements'));
    expect(
        await s.register(
            name: 'Test User', email: 'x@au.edu.pk', regNo: '239999', department: 'BBA', password: 'GoodPass1'),
        isNull);
    expect(s.currentUser?.email, 'x@au.edu.pk');
    expect(s.currentUser!.passwordHash.contains('GoodPass1'), isFalse);
  });

  test('approving a society request publishes it and notifies the student', () async {
    final s = await freshStore();
    await s.login('dev@loopair.app', 'admin123');
    final r = s.requests.first;
    final before = s.activeSocieties.length;
    s.decideRequest(r, true);
    expect(s.activeSocieties.length, before + 1);
    expect(s.notifications.any((n) => n.userId == r.submittedBy && n.title == 'Society approved'), isTrue);
  });

  test('slip lookup finds genuine codes only', () async {
    final s = await freshStore();
    final r = s.attendance.first;
    expect(s.findBySlip(r.slipCode.toLowerCase())?.id, r.id);
    expect(s.findBySlip('LA-XXXX-XXXX'), isNull);
  });
}

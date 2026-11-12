import 'package:flutter_test/flutter_test.dart';
import 'package:loopair/data/models.dart';
import 'package:loopair/data/seed.dart';
import 'package:loopair/services/location_service.dart';
import 'package:loopair/services/security.dart';

void main() {
  group('PasswordHasher', () {
    test('round-trips and rejects wrong passwords', () {
      final h = PasswordHasher.hash('Correct-horse1');
      expect(h.startsWith(r'pbkdf2$'), isTrue);
      expect(h.contains('Correct-horse1'), isFalse);
      expect(PasswordHasher.verify('Correct-horse1', h), isTrue);
      expect(PasswordHasher.verify('correct-horse1', h), isFalse);
    });

    test('same password gets a different salt each time', () {
      expect(PasswordHasher.hash('Abcdefg1'), isNot(PasswordHasher.hash('Abcdefg1')));
    });

    test('verifies the precomputed seed hashes (matches standard PBKDF2)', () {
      final seed = SeedData.build();
      final student = seed.users.firstWhere((u) => u.email == 'student@au.edu.pk');
      final admin = seed.users.firstWhere((u) => u.role == UserRole.admin);
      expect(PasswordHasher.verify('student123', student.passwordHash), isTrue);
      expect(PasswordHasher.verify('admin123', admin.passwordHash), isTrue);
      expect(PasswordHasher.verify('admin123', student.passwordHash), isFalse);
    });

    test('rejects malformed stored hashes', () {
      expect(PasswordHasher.verify('x', 'plain-text'), isFalse);
      expect(PasswordHasher.verify('x', r'pbkdf2$abc$AAAA$BBBB'), isFalse);
    });
  });

  group('PasswordPolicy', () {
    test('requires length, mixed case and a digit', () {
      expect(PasswordPolicy.ok('short1A'), isFalse);
      expect(PasswordPolicy.ok('alllowercase1'), isFalse);
      expect(PasswordPolicy.ok('NoDigitsHere'), isFalse);
      expect(PasswordPolicy.ok('GoodPass1'), isTrue);
    });
  });

  group('LoginThrottle', () {
    test('locks after five failures and clears on success', () {
      final t = LoginThrottle();
      for (var i = 0; i < 4; i++) {
        t.fail('a@au.edu.pk');
      }
      expect(t.lockRemaining('a@au.edu.pk'), isNull);
      t.fail('A@au.edu.pk');
      expect(t.lockRemaining('a@au.edu.pk'), isNotNull);
      t.success('a@au.edu.pk');
      expect(t.lockRemaining('a@au.edu.pk'), isNull);
    });
  });

  group('EmailRules', () {
    test('only university domains can self-register', () {
      expect(EmailRules.isUniversity('x@au.edu.pk'), isTrue);
      expect(EmailRules.isUniversity('x@students.au.edu.pk'), isTrue);
      expect(EmailRules.isUniversity('x@gmail.com'), isFalse);
    });
  });

  group('CheckInToken', () {
    final e = SeedData.build().events.first;
    test('current and previous window are valid, older are not', () {
      final now = DateTime(2026, 11, 12, 10, 0, 5);
      expect(CheckInToken.valid(e, CheckInToken.current(e, now), now), isTrue);
      final prev = now.subtract(const Duration(seconds: CheckInToken.period));
      expect(CheckInToken.valid(e, CheckInToken.current(e, prev), now), isTrue);
      final old = now.subtract(const Duration(seconds: CheckInToken.period * 3));
      expect(CheckInToken.valid(e, CheckInToken.current(e, old), now), isFalse);
    });

    test('payload parses back', () {
      final p = CheckInToken.parse(CheckInToken.payload(e));
      expect(p?.eventId, e.id);
      expect(CheckInToken.parse('https://example.com'), isNull);
    });
  });

  group('Perm', () {
    final seed = SeedData.build();
    AppUser u(String id) => seed.users.firstWhere((x) => x.id == id);
    final aucisMeeting = seed.events.firstWhere((e) => e.id == 'e_aucis_meet');

    test('only the society focal faculty or admin can verify', () {
      expect(Perm.verifyAttendance(u('u_f1'), aucisMeeting), isTrue); // AUCIS focal
      expect(Perm.verifyAttendance(u('u_f2'), aucisMeeting), isFalse); // GDGoC focal
      expect(Perm.verifyAttendance(u('u_s1'), aucisMeeting), isFalse); // student
      expect(Perm.verifyAttendance(u('u_admin'), aucisMeeting), isTrue);
    });

    test('society accounts manage only their own society', () {
      expect(Perm.manageSociety(u('u_soc1'), 's_aucis'), isTrue);
      expect(Perm.manageSociety(u('u_soc1'), 's_gdgoc'), isFalse);
    });

    test('only students check in', () {
      expect(Perm.checkIn(u('u_s1')), isTrue);
      expect(Perm.checkIn(u('u_f1')), isFalse);
    });
  });

  test('slip codes are stable and well formed', () {
    final r = SeedData.build().attendance.first;
    expect(RegExp(r'^LA-[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(r.slipCode), isTrue);
    expect(r.slipCode, SeedData.build().attendance.first.slipCode);
  });
}

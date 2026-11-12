import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;

import '../data/models.dart';

/// Password hashing with PBKDF2-HMAC-SHA256 and a per-user random salt.
///
/// Stored form: `pbkdf2$<iterations>$<saltB64>$<hashB64>`. Plain-text
/// passwords are never persisted. Comparison is constant-time.
class PasswordHasher {
  PasswordHasher._();

  /// Kept moderate so hashing stays fast on low-end phones and on web.
  /// When a server backend is added, hash there with a higher work factor
  /// (or Argon2id) and treat this as defence in depth.
  /// Native builds: 12k. Web (compiled JS, no native crypto here) uses
  /// fewer so sign-in stays responsive. The count is stored in each hash.
  static const iterations = kIsWeb ? 2500 : 12000;
  static const _keyLen = 32;
  static final _rng = Random.secure();

  static String hash(String password, {String? saltB64, int iter = iterations}) {
    final salt = saltB64 != null
        ? base64Decode(saltB64)
        : Uint8List.fromList(List.generate(16, (_) => _rng.nextInt(256)));
    final dk = _pbkdf2(utf8.encode(password), salt, iter, _keyLen);
    return 'pbkdf2\$$iter\$${base64Encode(salt)}\$${base64Encode(dk)}';
  }

  /// Off the UI isolate on mobile (no jank while the spinner turns).
  /// On web `compute` runs inline, which is fine at the web work factor.
  static Future<bool> verifyAsync(String password, String stored) =>
      compute(_verifyArgs, [password, stored]);
  static Future<String> hashAsync(String password) => compute(_hashArg, password);
  static bool _verifyArgs(List<String> a) => verify(a[0], a[1]);
  static String _hashArg(String p) => hash(p);

  static bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iter = int.tryParse(parts[1]);
    if (iter == null) return false;
    final candidate = hash(password, saltB64: parts[2], iter: iter);
    return _constantTimeEquals(candidate, stored);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }

  static Uint8List _pbkdf2(List<int> pw, List<int> salt, int iter, int len) {
    final hmac = Hmac(sha256, pw);
    final out = BytesBuilder();
    var block = 1;
    while (out.length < len) {
      final s = BytesBuilder()
        ..add(salt)
        ..add([block >> 24 & 0xff, block >> 16 & 0xff, block >> 8 & 0xff, block & 0xff]);
      var u = hmac.convert(s.toBytes()).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iter; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
      block++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, len));
  }
}

/// Password rules shown live on sign-up and change-password forms.
class PasswordPolicy {
  PasswordPolicy._();
  static const rules = <(String, bool Function(String))>[
    ('At least 8 characters', _len),
    ('An uppercase and a lowercase letter', _case),
    ('At least one number', _digit),
  ];
  static bool _len(String s) => s.length >= 8;
  static bool _case(String s) => s.contains(RegExp(r'[A-Z]')) && s.contains(RegExp(r'[a-z]'));
  static bool _digit(String s) => s.contains(RegExp(r'\d'));

  static bool ok(String s) => rules.every((r) => r.$2(s));
  static String? validate(String? s) =>
      (s == null || !ok(s)) ? 'Password does not meet the requirements' : null;
}

/// Brute-force protection: 5 failures locks the email for a growing period.
class LoginThrottle {
  final Map<String, int> _fails = {};
  final Map<String, DateTime> _lockedUntil = {};

  /// Persisted so restarting the app does not reset the lockout.
  Map<String, dynamic> toJson() => {
        'fails': _fails,
        'locked': _lockedUntil.map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  void restore(Map<String, dynamic> j) {
    _fails
      ..clear()
      ..addAll(Map<String, int>.from(j['fails'] ?? const {}));
    _lockedUntil
      ..clear()
      ..addAll((Map<String, dynamic>.from(j['locked'] ?? const {}))
          .map((k, v) => MapEntry(k, DateTime.parse(v as String))));
  }

  Duration? lockRemaining(String email) {
    final u = _lockedUntil[email.toLowerCase()];
    if (u == null) return null;
    final d = u.difference(DateTime.now());
    return d.isNegative ? null : d;
  }

  void fail(String email) {
    final k = email.toLowerCase();
    final n = (_fails[k] ?? 0) + 1;
    _fails[k] = n;
    if (n >= 5) {
      final mins = [1, 5, 15][((n - 5) ~/ 5).clamp(0, 2)];
      _lockedUntil[k] = DateTime.now().add(Duration(minutes: mins));
    }
  }

  int attemptsLeft(String email) => (5 - ((_fails[email.toLowerCase()] ?? 0) % 5)).clamp(0, 5);

  void success(String email) {
    _fails.remove(email.toLowerCase());
    _lockedUntil.remove(email.toLowerCase());
  }
}

/// Central authorisation rules. Every mutating store call checks these,
/// so a screen that forgets to hide a button still cannot do damage.
class Perm {
  Perm._();

  static bool isAdmin(AppUser? u) => u?.role == UserRole.admin;

  /// Society account or faculty focal person of that society, or admin.
  static bool manageSociety(AppUser? u, String societyId) =>
      u != null &&
      u.active &&
      (u.role == UserRole.admin ||
          ((u.role == UserRole.society || u.role == UserRole.faculty) && u.societyId == societyId));

  /// Only the faculty focal person of the event's society (or admin) verifies.
  static bool verifyAttendance(AppUser? u, CampusEvent e) =>
      u != null &&
      u.active &&
      (u.role == UserRole.admin || (u.role == UserRole.faculty && u.societyId == e.societyId));

  static bool checkIn(AppUser? u) => u != null && u.active && u.role == UserRole.student;

  static bool editLost(AppUser? u, LostItem i) =>
      u != null && (u.role == UserRole.admin || u.id == i.postedBy);

  static bool postAnnouncement(AppUser? u, String? societyId) =>
      u != null &&
      (u.role == UserRole.admin || (societyId != null && manageSociety(u, societyId)));
}

class PermissionDenied implements Exception {
  final String message;
  PermissionDenied([this.message = 'You do not have permission to do that']);
  @override
  String toString() => message;
}

/// Validates university email domains for self sign-up.
class EmailRules {
  EmailRules._();
  static const allowedDomains = ['au.edu.pk', 'students.au.edu.pk', 'mail.au.edu.pk'];
  static bool isUniversity(String email) {
    final at = email.lastIndexOf('@');
    if (at < 1) return false;
    return allowedDomains.contains(email.substring(at + 1).toLowerCase());
  }

  static final _re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static bool valid(String e) => _re.hasMatch(e.trim());
}

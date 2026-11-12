import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';
import '../services/security.dart';
import 'models.dart';
import 'seed.dart';

/// Outcome of an attendance action, for UI feedback.
class ActionResult {
  final bool ok;
  final String message;
  final AttendanceRecord? record;
  const ActionResult(this.ok, this.message, [this.record]);
}

class Anomaly {
  final String title;
  final String detail;
  final AttendanceRecord? record;
  final String severity; // high | medium | low
  const Anomaly(this.title, this.detail, this.severity, [this.record]);
}

/// Single source of truth. Local-first: everything persists to device storage
/// as JSON. The public API is shaped so a remote backend (Firebase, Supabase,
/// REST) can replace the persistence layer without touching the screens.
class AppStore extends ChangeNotifier {
  static const _key = 'loopair.state.v1';
  static const _sessionKey = 'loopair.session.v1';
  static const _onboardKey = 'loopair.onboarded';
  static const _throttleKey = 'loopair.throttle.v1';

  List<AppUser> users = [];
  List<Society> societies = [];
  List<CampusEvent> events = [];
  List<AttendanceRecord> attendance = [];
  List<SocietyRequest> requests = [];
  List<LostItem> lostItems = [];
  List<Announcement> announcements = [];
  List<EventFeedback> feedback = [];
  List<AuditEntry> audit = [];
  List<AppNotification> notifications = [];
  final throttle = LoginThrottle();
  bool onboarded = false;

  AppUser? currentUser;
  bool ready = false;

  final _rand = Random();
  String newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(999)}';

  // ------------------------------------------------------------ persistence
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _applySeed();
    } else {
      try {
        _fromJson(jsonDecode(raw));
      } catch (_) {
        _applySeed();
      }
    }
    final sid = prefs.getString(_sessionKey);
    if (sid != null) {
      final u = userById(sid);
      currentUser = (u != null && u.active) ? u : null;
    }
    onboarded = prefs.getBool(_onboardKey) ?? false;
    final t = prefs.getString(_throttleKey);
    if (t != null) {
      try {
        throttle.restore(jsonDecode(t));
      } catch (_) {}
    }
    ready = true;
    await _save();
    notifyListeners();
  }

  void _applySeed() {
    final s = SeedData.build();
    users = s.users;
    societies = s.societies;
    events = s.events;
    attendance = s.attendance;
    requests = s.requests;
    lostItems = s.lostItems;
    announcements = s.announcements;
    feedback = s.feedback;
    audit = [AuditEntry(at: DateTime.now(), actorId: 'system', action: 'Demo data initialised')];
    final now = DateTime.now();
    notifications = [
      AppNotification(
          id: 'nt1',
          userId: 'u_s1',
          kind: NoticeKind.attendance,
          title: 'Attendance verified',
          body: 'Dr. Saima Iqbal verified your attendance for AUCIS Committee Heads Meeting.',
          createdAt: now.subtract(const Duration(days: 2))),
      AppNotification(
          id: 'nt2',
          userId: 'u_s1',
          kind: NoticeKind.event,
          title: 'Check-in is open',
          body: 'Seerah-un-Nabi Seminar 2026 is live in the Main Auditorium.',
          createdAt: now.subtract(const Duration(minutes: 20))),
    ];
  }

  void _fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        (j[k] as List? ?? const []).map((e) => f(Map<String, dynamic>.from(e))).toList();
    users = list('users', AppUser.fromJson);
    societies = list('societies', Society.fromJson);
    events = list('events', CampusEvent.fromJson);
    attendance = list('attendance', AttendanceRecord.fromJson);
    requests = list('requests', SocietyRequest.fromJson);
    lostItems = list('lostItems', LostItem.fromJson);
    announcements = list('announcements', Announcement.fromJson);
    feedback = list('feedback', EventFeedback.fromJson);
    audit = list('audit', AuditEntry.fromJson);
    notifications = list('notifications', AppNotification.fromJson);
  }

  Map<String, dynamic> _toJson() => {
        'users': users.map((e) => e.toJson()).toList(),
        'societies': societies.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'requests': requests.map((e) => e.toJson()).toList(),
        'lostItems': lostItems.map((e) => e.toJson()).toList(),
        'announcements': announcements.map((e) => e.toJson()).toList(),
        'feedback': feedback.map((e) => e.toJson()).toList(),
        'audit': audit.take(400).map((e) => e.toJson()).toList(),
        'notifications': notifications.take(300).map((e) => e.toJson()).toList(),
      };

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson()));
  }

  void _commit(String? auditAction) {
    if (auditAction != null) {
      audit.insert(
          0, AuditEntry(at: DateTime.now(), actorId: currentUser?.id ?? 'system', action: auditAction));
    }
    notifyListeners();
    _save();
  }

  Future<void> resetDemoData() async {
    _guard(Perm.isAdmin(currentUser));
    _applySeed();
    final keep = currentUser?.id;
    currentUser = keep == null ? null : userById(keep);
    _commit('Reset all data to demo seed');
  }

  // ------------------------------------------------------------------ auth
  Future<void> completeOnboarding() async {
    onboarded = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardKey, true);
  }

  void _startSession(AppUser u) {
    currentUser = u;
    SharedPreferences.getInstance().then((p) => p.setString(_sessionKey, u.id));
    notifyListeners();
  }

  void _saveThrottle() => SharedPreferences.getInstance()
      .then((p) => p.setString(_throttleKey, jsonEncode(throttle.toJson())));

  static const _dummyHash =
      r'pbkdf2$2500$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

  /// Returns an error message, or null on success. Same message for unknown
  /// email and wrong password so accounts cannot be enumerated.
  Future<String?> login(String email, String password) async {
    final key = email.trim().toLowerCase();
    final lock = throttle.lockRemaining(key);
    if (lock != null) {
      final m = lock.inMinutes, sec = lock.inSeconds % 60;
      return 'Too many attempts. Try again in ${m > 0 ? '$m min ' : ''}${sec}s.';
    }
    final u = users.where((u) => u.email.toLowerCase() == key).firstOrNull;
    // Hash even for unknown emails so response time doesn't reveal them.
    final ok = await PasswordHasher.verifyAsync(password, u?.passwordHash ?? _dummyHash);
    if (u == null || !ok) {
      throttle.fail(key);
      _saveThrottle();
      final left = throttle.attemptsLeft(key);
      final lockNow = throttle.lockRemaining(key);
      if (lockNow != null) return 'Too many attempts. Account locked for ${lockNow.inMinutes + 1} min.';
      return left <= 2
          ? 'Email or password is incorrect. $left attempt${left == 1 ? '' : 's'} left.'
          : 'Email or password is incorrect';
    }
    if (!u.active) return 'This account has been deactivated. Contact the administrator.';
    throttle.success(key);
    _saveThrottle();
    _startSession(u);
    return null;
  }

  /// Student self-registration. Faculty and society accounts are created by
  /// the administrator only.
  Future<String?> register({
    required String name,
    required String email,
    required String regNo,
    required String department,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (!EmailRules.valid(e)) return 'Enter a valid email address';
    if (!EmailRules.isUniversity(e)) return 'Use your Air University email (@au.edu.pk)';
    if (emailTaken(e)) return 'An account with this email already exists';
    if (users.any((u) => u.regNo == regNo.trim())) {
      return 'This registration number is already linked to an account';
    }
    if (!PasswordPolicy.ok(password)) return 'Password does not meet the requirements';
    final u = AppUser(
      id: newId('u'),
      name: name.trim(),
      email: e,
      passwordHash: await PasswordHasher.hashAsync(password),
      role: UserRole.student,
      regNo: regNo.trim(),
      department: department,
    );
    users.add(u);
    _notify(u.id, NoticeKind.system, 'Welcome to LoopAir',
        'Browse societies, check in to events and keep your attendance slips in one place.');
    audit.insert(0, AuditEntry(at: DateTime.now(), actorId: u.id, action: 'Student registered: ${u.email}'));
    _save();
    _startSession(u);
    return null;
  }

  Future<String?> changePassword(String current, String next) async {
    final u = currentUser;
    if (u == null) return 'Not signed in';
    if (!await PasswordHasher.verifyAsync(current, u.passwordHash)) {
      return 'Current password is incorrect';
    }
    if (!PasswordPolicy.ok(next)) return 'New password does not meet the requirements';
    if (current == next) return 'New password must be different';
    u.passwordHash = await PasswordHasher.hashAsync(next);
    _commit('Changed own password');
    return null;
  }

  /// Required by Play Store policy: users can delete their own account.
  Future<String?> deleteOwnAccount(String password) async {
    final u = currentUser;
    if (u == null) return 'Not signed in';
    if (u.role == UserRole.admin) return 'Administrator accounts cannot be self-deleted';
    if (!await PasswordHasher.verifyAsync(password, u.passwordHash)) return 'Password is incorrect';
    currentUser = null;
    _deleteUserData(u);
    audit.insert(0, AuditEntry(at: DateTime.now(), actorId: u.id, action: 'Account self-deleted: ${u.email}'));
    SharedPreferences.getInstance().then((p) => p.remove(_sessionKey));
    notifyListeners();
    _save();
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_sessionKey);
    notifyListeners();
  }

  void _guard(bool allowed) {
    if (!allowed) throw PermissionDenied();
  }

  // ---------------------------------------------------------- notifications
  void _notify(String userId, NoticeKind kind, String title, String body, [String? refId]) {
    notifications.insert(
        0,
        AppNotification(
            id: newId('nt'),
            userId: userId,
            kind: kind,
            title: title,
            body: body,
            createdAt: DateTime.now(),
            refId: refId));
  }

  List<AppNotification> myNotifications() =>
      notifications.where((n) => n.userId == currentUser?.id).toList();

  int get unreadCount => myNotifications().where((n) => !n.read).length;

  void markAllRead() {
    for (final n in myNotifications()) {
      n.read = true;
    }
    _commit(null);
  }

  // --------------------------------------------------------------- lookups
  AppUser? userById(String? id) => users.where((u) => u.id == id).firstOrNull;
  Society? societyById(String? id) => societies.where((s) => s.id == id).firstOrNull;
  CampusEvent? eventById(String? id) => events.where((e) => e.id == id).firstOrNull;
  AttendanceRecord? recordById(String id) => attendance.where((r) => r.id == id).firstOrNull;

  List<Society> get activeSocieties =>
      societies.where((s) => s.status == SocietyStatus.active).toList()
        ..sort((a, b) => a.shortName.compareTo(b.shortName));

  List<CampusEvent> get visibleEvents =>
      events.where((e) => e.status == EventStatus.published).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

  List<CampusEvent> eventsForSociety(String sid) =>
      events.where((e) => e.societyId == sid).toList()..sort((a, b) => b.startAt.compareTo(a.startAt));

  List<AttendanceRecord> recordsForEvent(String eid) =>
      attendance.where((r) => r.eventId == eid).toList()..sort((a, b) => b.checkInAt.compareTo(a.checkInAt));

  List<AttendanceRecord> recordsForUser(String uid) =>
      attendance.where((r) => r.userId == uid).toList()..sort((a, b) => b.checkInAt.compareTo(a.checkInAt));

  AttendanceRecord? recordFor(String eventId, String userId) =>
      attendance.where((r) => r.eventId == eventId && r.userId == userId).firstOrNull;

  /// The student's currently-open check-in, if any (drives the "Leave" banner).
  AttendanceRecord? openRecordFor(String uid) {
    final now = DateTime.now();
    return attendance.where((r) {
      if (r.userId != uid || !r.isOpen) return false;
      final e = eventById(r.eventId);
      return e != null && e.mode == AttendanceMode.checkInOut && !e.isPast(now);
    }).firstOrNull;
  }

  List<Announcement> announcementsFor(AppUser u) {
    final mine = societies.where((s) => s.memberIds.contains(u.id)).map((s) => s.id).toSet();
    if (u.societyId != null) mine.add(u.societyId!);
    final list = announcements
        .where((a) => a.societyId == null || mine.contains(a.societyId) || u.role == UserRole.admin)
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  double? averageRating(String eventId) {
    final f = feedback.where((x) => x.eventId == eventId).toList();
    if (f.isEmpty) return null;
    return f.map((e) => e.rating).reduce((a, b) => a + b) / f.length;
  }

  /// Co-curricular hours: sum of verified/recorded attendance durations.
  Duration activityHours(String uid) {
    var total = Duration.zero;
    for (final r in recordsForUser(uid)) {
      if (r.status == AttendanceStatus.rejected) continue;
      if (r.duration != null) {
        total += r.duration!;
      } else if (r.status == AttendanceStatus.verified) {
        final e = eventById(r.eventId);
        if (e != null) total += e.endAt.difference(e.startAt);
      }
    }
    return total;
  }

  // ------------------------------------------------------------ attendance
  List<String> _locationFlags(CampusEvent e, GeoStamp loc, String? locError) {
    if (!loc.known) return ['No location'];
    final d = LocationService.distance(loc.lat!, loc.lng!, e.lat, e.lng);
    if (d > e.radiusMeters) {
      final txt = d >= 1000 ? '${(d / 1000).toStringAsFixed(1)} km' : '${d.round()} m';
      return ['Outside venue ($txt away)'];
    }
    return [];
  }

  ActionResult checkIn(CampusEvent e, CheckMethod method, GeoStamp loc,
      {String? locError, String? token}) {
    final u = currentUser!;
    if (!Perm.checkIn(u)) return const ActionResult(false, 'Only student accounts can check in');
    final now = DateTime.now();
    if (e.status != EventStatus.published) return const ActionResult(false, 'This event was cancelled');
    if (!e.checkInOpen) return const ActionResult(false, 'Check-in has not been opened by the organiser yet');
    if (!e.isLive(now)) return const ActionResult(false, 'Check-in is only available during the event window');
    final needsToken = method == CheckMethod.qr || method == CheckMethod.code;
    if (needsToken && (token == null || !CheckInToken.valid(e, token))) {
      return const ActionResult(false, 'This code has expired. Scan the current QR on the screen.');
    }
    if (method == CheckMethod.marked && !e.isMeeting) {
      return const ActionResult(false, 'Use the QR or Check in button for this event');
    }
    final elsewhere = openRecordFor(u.id);
    if (elsewhere != null && elsewhere.eventId != e.id) {
      return ActionResult(false,
          'You are still checked in to ${eventById(elsewhere.eventId)?.title}. Tap Leave there first.');
    }
    final existing = recordFor(e.id, u.id);
    if (existing != null) {
      if (existing.isOpen) return ActionResult(false, 'You are already checked in', existing);
      return ActionResult(false, 'You have already checked in and left this event', existing);
    }
    final flags = _locationFlags(e, loc, locError);
    // A rotating-code check-in proves presence at the gate. An in-app tap
    // without a good location fix does not, so it waits for a human.
    final trusted = needsToken || flags.isEmpty;
    final r = AttendanceRecord(
      id: newId('a'),
      eventId: e.id,
      userId: u.id,
      checkInAt: now,
      checkInLoc: loc,
      checkInMethod: method,
      status: e.isMeeting || !trusted ? AttendanceStatus.pending : AttendanceStatus.recorded,
      flags: flags,
    );
    attendance.add(r);
    if (!e.registeredIds.contains(u.id)) e.registeredIds.add(u.id);
    _commit(null);
    return ActionResult(
        true,
        e.isMeeting
            ? 'Marked present. Waiting for faculty verification.'
            : trusted
                ? 'Checked in at ${_hm(now)}. Remember to tap Leave when you go.'
                : 'Checked in at ${_hm(now)}. Your location could not confirm you are at the venue, '
                    'so the organiser will verify it. Scanning the gate QR avoids this.',
        r);
  }

  ActionResult checkOut(AttendanceRecord r, GeoStamp loc, {String? locError}) {
    if (r.userId != currentUser?.id) return const ActionResult(false, 'This is not your record');
    if (!r.isOpen) return const ActionResult(false, 'Already checked out');
    final e = eventById(r.eventId)!;
    final now = DateTime.now();
    r.checkOutAt = now;
    r.checkOutLoc = loc;
    final outFlags = _locationFlags(e, loc, locError).map((f) => '$f at leave');
    r.flags.addAll(outFlags);
    final stayed = now.difference(r.checkInAt);
    final planned = e.endAt.difference(e.startAt);
    if (stayed < planned * 0.5 && now.isBefore(e.endAt)) {
      r.flags.add('Left early (${stayed.inMinutes < 1 ? '< 1' : stayed.inMinutes} min)');
    }
    _commit(null);
    return ActionResult(true, 'Left at ${_hm(now)} · stayed ${stayed.inMinutes < 1 ? 'under a minute' : _dur(stayed)}', r);
  }

  void review(AttendanceRecord r, bool approve, {String? note}) {
    _guard(Perm.verifyAttendance(currentUser, eventById(r.eventId)!));
    r.status = approve ? AttendanceStatus.verified : AttendanceStatus.rejected;
    r.reviewedBy = currentUser?.id;
    r.reviewedAt = DateTime.now();
    r.note = note;
    final u = userById(r.userId);
    _notify(
        r.userId,
        NoticeKind.attendance,
        approve ? 'Attendance verified' : 'Attendance not accepted',
        '${currentUser?.name} ${approve ? 'verified' : 'rejected'} your attendance for '
            '${eventById(r.eventId)?.title}${note != null && note.isNotEmpty ? ': $note' : '.'}',
        r.id);
    _commit('${approve ? 'Verified' : 'Rejected'} attendance of ${u?.name ?? r.userId} '
        'for ${eventById(r.eventId)?.title ?? r.eventId}');
  }

  void addManualAttendance(CampusEvent e, AppUser student) {
    _guard(Perm.verifyAttendance(currentUser, e));
    if (recordFor(e.id, student.id) != null) return;
    attendance.add(AttendanceRecord(
      id: newId('a'),
      eventId: e.id,
      userId: student.id,
      checkInAt: e.startAt,
      checkInLoc: const GeoStamp(),
      checkInMethod: CheckMethod.manual,
      checkOutAt: e.endAt,
      checkOutLoc: const GeoStamp(),
      status: AttendanceStatus.verified,
      reviewedBy: currentUser?.id,
      reviewedAt: DateTime.now(),
      note: 'Added manually',
    ));
    _commit('Manually added ${student.name} to ${e.title}');
  }

  void updateRecord(AttendanceRecord r) {
    _guard(Perm.isAdmin(currentUser));
    _commit('Edited attendance record ${r.id}');
  }

  void deleteRecord(AttendanceRecord r) {
    _guard(Perm.isAdmin(currentUser));
    attendance.remove(r);
    _commit('Deleted attendance record of ${userById(r.userId)?.name} for ${eventById(r.eventId)?.title}');
  }

  void clearFlags(AttendanceRecord r) {
    _guard(Perm.isAdmin(currentUser));
    r.flags.clear();
    _commit('Cleared flags on record ${r.id}');
  }

  /// Instructor-facing lookup: is this slip code genuine?
  AttendanceRecord? findBySlip(String code) {
    final c = code.trim().toUpperCase().replaceAll(' ', '');
    return attendance.where((r) => r.slipCode == c).firstOrNull;
  }

  /// Integrity issues the admin should look at.
  List<Anomaly> get anomalies {
    final now = DateTime.now();
    final out = <Anomaly>[];
    for (final r in attendance) {
      final e = eventById(r.eventId);
      final u = userById(r.userId);
      if (e == null || u == null) {
        out.add(Anomaly('Orphaned record', 'Record ${r.id} points to a deleted user or event', 'high', r));
        continue;
      }
      for (final f in r.flags) {
        final sev = f.contains('Outside') ? 'high' : 'medium';
        out.add(Anomaly(f, '${u.name} · ${e.title}', sev, r));
      }
      if (r.isOpen && e.mode == AttendanceMode.checkInOut && e.isPast(now) && !r.flags.any((f) => f.contains('No check-out'))) {
        out.add(Anomaly('No check-out recorded', '${u.name} · ${e.title}', 'medium', r));
      }
      if (r.status == AttendanceStatus.pending && e.isPast(now)) {
        out.add(Anomaly('Unverified after event ended', '${u.name} · ${e.title}', 'low', r));
      }
    }
    // Same student checked in to two overlapping events
    final byUser = <String, List<AttendanceRecord>>{};
    for (final r in attendance.where((r) => r.status != AttendanceStatus.rejected)) {
      byUser.putIfAbsent(r.userId, () => []).add(r);
    }
    byUser.forEach((uid, list) {
      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          final a = eventById(list[i].eventId), b = eventById(list[j].eventId);
          if (a == null || b == null) continue;
          if (a.startAt.isBefore(b.endAt) && b.startAt.isBefore(a.endAt)) {
            out.add(Anomaly('Present at two events at once',
                '${userById(uid)?.name}: ${a.title} and ${b.title}', 'high', list[j]));
          }
        }
      }
    });
    for (final s in societies) {
      if (s.status == SocietyStatus.active && s.focalFacultyId == null) {
        out.add(Anomaly('Society without a faculty focal person',
            '${s.shortName} cannot have meetings verified', 'low'));
      }
    }
    const rank = {'high': 0, 'medium': 1, 'low': 2};
    out.sort((a, b) => rank[a.severity]!.compareTo(rank[b.severity]!));
    return out;
  }

  // --------------------------------------------------------------- events
  /// Other published events sharing the venue and overlapping in time.
  List<CampusEvent> clashesFor(String venue, DateTime start, DateTime end, {String? ignoreId}) =>
      events
          .where((e) =>
              e.id != ignoreId &&
              e.status == EventStatus.published &&
              e.venue == venue &&
              e.startAt.isBefore(end) &&
              start.isBefore(e.endAt))
          .toList();

  void saveEvent(CampusEvent e) {
    _guard(Perm.manageSociety(currentUser, e.societyId));
    final i = events.indexWhere((x) => x.id == e.id);
    if (i == -1) {
      events.add(e);
      final s = societyById(e.societyId);
      for (final m in s?.memberIds ?? const <String>[]) {
        _notify(m, NoticeKind.event, 'New from ${s!.shortName}',
            '${e.title} · ${e.venue}', e.id);
      }
      _commit('Created event "${e.title}"');
    } else {
      events[i] = e;
      _commit('Updated event "${e.title}"');
    }
  }

  void setCheckInOpen(CampusEvent e, bool open) {
    _guard(Perm.manageSociety(currentUser, e.societyId));
    e.checkInOpen = open;
    _commit('${open ? 'Opened' : 'Closed'} check-in for "${e.title}"');
  }

  void cancelEvent(CampusEvent e) {
    _guard(Perm.manageSociety(currentUser, e.societyId));
    for (final uid in e.registeredIds) {
      _notify(uid, NoticeKind.event, 'Event cancelled', '${e.title} has been cancelled.', e.id);
    }
    e.status = EventStatus.cancelled;
    e.checkInOpen = false;
    _commit('Cancelled event "${e.title}"');
  }

  void deleteEvent(CampusEvent e) {
    _guard(Perm.isAdmin(currentUser) || Perm.manageSociety(currentUser, e.societyId));
    events.remove(e);
    attendance.removeWhere((r) => r.eventId == e.id);
    feedback.removeWhere((f) => f.eventId == e.id);
    _commit('Deleted event "${e.title}" and its records');
  }

  /// Returns an error message, or null on success.
  String? toggleRegistration(CampusEvent e) {
    final uid = currentUser!.id;
    if (e.registeredIds.contains(uid)) {
      e.registeredIds.remove(uid);
    } else {
      if (e.status == EventStatus.cancelled) return 'This event was cancelled';
      if (e.isPast(DateTime.now())) return 'This event has already ended';
      if (e.capacity > 0 && e.registeredIds.length >= e.capacity) {
        return 'This event is full (${e.capacity} seats)';
      }
      e.registeredIds.add(uid);
    }
    _commit(null);
    return null;
  }

  void submitFeedback(CampusEvent e, int rating, String comment) {
    final uid = currentUser!.id;
    feedback.removeWhere((f) => f.eventId == e.id && f.userId == uid);
    feedback.add(EventFeedback(
        id: newId('fb'),
        eventId: e.id,
        userId: uid,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now()));
    _commit(null);
  }

  EventFeedback? myFeedback(String eventId) =>
      feedback.where((f) => f.eventId == eventId && f.userId == currentUser?.id).firstOrNull;

  // ------------------------------------------------------------ societies
  void requestJoin(Society s) {
    final uid = currentUser!.id;
    if (s.memberIds.contains(uid) || s.pendingMemberIds.contains(uid)) return;
    s.pendingMemberIds.add(uid);
    _commit(null);
  }

  void leaveSociety(Society s) {
    final uid = currentUser!.id;
    s.memberIds.remove(uid);
    s.pendingMemberIds.remove(uid);
    _commit(null);
  }

  void decideMember(Society s, String uid, bool accept) {
    _guard(Perm.manageSociety(currentUser, s.id));
    _notify(uid, NoticeKind.membership, accept ? 'Welcome to ${s.shortName}' : 'Membership request declined',
        accept
            ? 'Your request to join ${s.name} was accepted.'
            : '${s.shortName} could not accept your request right now.',
        s.id);
    s.pendingMemberIds.remove(uid);
    if (accept && !s.memberIds.contains(uid)) s.memberIds.add(uid);
    _commit('${accept ? 'Accepted' : 'Declined'} ${userById(uid)?.name} for ${s.shortName}');
  }

  void removeMember(Society s, String uid) {
    _guard(Perm.manageSociety(currentUser, s.id));
    s.memberIds.remove(uid);
    _commit('Removed ${userById(uid)?.name} from ${s.shortName}');
  }

  void saveSociety(Society s) {
    _guard(Perm.isAdmin(currentUser) || Perm.manageSociety(currentUser, s.id));
    final i = societies.indexWhere((x) => x.id == s.id);
    if (i == -1) {
      societies.add(s);
      _commit('Created society ${s.shortName}');
    } else {
      societies[i] = s;
      _commit('Updated society ${s.shortName}');
    }
    // keep faculty/society-account bindings consistent
    for (final u in users) {
      if (u.role == UserRole.faculty && u.id == s.focalFacultyId) u.societyId = s.id;
      if (u.role == UserRole.society && u.id == s.accountUserId) u.societyId = s.id;
    }
  }

  void setSocietyStatus(Society s, SocietyStatus st) {
    _guard(Perm.isAdmin(currentUser));
    s.status = st;
    _commit('${st == SocietyStatus.active ? 'Reactivated' : 'Suspended'} ${s.shortName}');
  }

  void deleteSociety(Society s) {
    _guard(Perm.isAdmin(currentUser));
    final evIds = events.where((e) => e.societyId == s.id).map((e) => e.id).toSet();
    events.removeWhere((e) => evIds.contains(e.id));
    attendance.removeWhere((r) => evIds.contains(r.eventId));
    announcements.removeWhere((a) => a.societyId == s.id);
    for (final u in users) {
      if (u.societyId == s.id) u.societyId = null;
    }
    societies.remove(s);
    _commit('Deleted society ${s.shortName} with ${evIds.length} events');
  }

  // ------------------------------------------------------------- requests
  void submitRequest(SocietyRequest r) {
    requests.add(r);
    _commit(null);
  }

  void decideRequest(SocietyRequest r, bool approve, {String? note, bool publish = true}) {
    _guard(Perm.isAdmin(currentUser));
    _notify(
        r.submittedBy,
        NoticeKind.society,
        approve ? 'Society approved' : 'Society request not approved',
        approve
            ? '${r.name} was approved${publish ? ' and is now listed' : ''}.'
            : '${r.name}: ${note?.isNotEmpty == true ? note : 'see the Office of Student Affairs for details.'}',
        r.id);
    r.status = approve ? RequestStatus.approved : RequestStatus.rejected;
    r.adminNote = note;
    r.publishOnApproval = publish;
    if (approve) {
      const palette = [0xFF35577D, 0xFF5B4A8B, 0xFF2F6B4F, 0xFF8A4B2A, 0xFF4A5568, 0xFF6B3A5B];
      final s = Society(
        id: newId('s'),
        name: r.name,
        shortName: r.shortName,
        category: r.category,
        description: '${r.mission}\n\n${r.activities}',
        colorValue: palette[societies.length % palette.length],
        foundedYear: DateTime.now().year,
        contactEmail: r.contactEmail,
        status: publish ? SocietyStatus.active : SocietyStatus.suspended,
        memberIds: [r.submittedBy],
      );
      societies.add(s);
    }
    _commit('${approve ? 'Approved' : 'Rejected'} society request "${r.name}"'
        '${approve ? (publish ? ' and published it' : ' (kept unpublished)') : ''}');
  }

  void deleteRequest(SocietyRequest r) {
    _guard(Perm.isAdmin(currentUser));
    requests.remove(r);
    _commit('Deleted society request "${r.name}"');
  }

  // ---------------------------------------------------------------- users
  /// Admin create/update. [newPassword] is hashed; null keeps the current hash.
  void saveUser(AppUser u, {String? newPassword}) {
    _guard(Perm.isAdmin(currentUser));
    if (newPassword != null && newPassword.isNotEmpty) {
      u.passwordHash = PasswordHasher.hash(newPassword);
    }
    final i = users.indexWhere((x) => x.id == u.id);
    if (i == -1) {
      users.add(u);
      _commit('Created ${u.role.label.toLowerCase()} ${u.name}');
    } else {
      users[i] = u;
      _commit('Updated user ${u.name}${newPassword != null && newPassword.isNotEmpty ? ' (password reset)' : ''}');
    }
  }

  void setUserActive(AppUser u, bool active) {
    _guard(Perm.isAdmin(currentUser));
    if (u.id == currentUser?.id) throw PermissionDenied('You cannot deactivate your own account');
    u.active = active;
    _commit('${active ? 'Activated' : 'Deactivated'} ${u.name}');
  }

  void deleteUser(AppUser u) {
    _guard(Perm.isAdmin(currentUser));
    if (u.id == currentUser?.id) throw PermissionDenied('You cannot delete your own account here');
    _deleteUserData(u);
    _commit('Deleted user ${u.name}');
  }

  void _deleteUserData(AppUser u) {
    users.remove(u);
    attendance.removeWhere((r) => r.userId == u.id);
    feedback.removeWhere((f) => f.userId == u.id);
    notifications.removeWhere((n) => n.userId == u.id);
    lostItems.removeWhere((l) => l.postedBy == u.id);
    for (final s in societies) {
      s.memberIds.remove(u.id);
      s.pendingMemberIds.remove(u.id);
      if (s.focalFacultyId == u.id) s.focalFacultyId = null;
      if (s.accountUserId == u.id) s.accountUserId = null;
    }
    for (final e in events) {
      e.registeredIds.remove(u.id);
    }
  }

  bool emailTaken(String email, {String? exceptId}) =>
      users.any((u) => u.email.toLowerCase() == email.toLowerCase() && u.id != exceptId);

  // ----------------------------------------------------------- lost/found
  void saveLostItem(LostItem i) {
    _guard(Perm.editLost(currentUser, i));
    final idx = lostItems.indexWhere((x) => x.id == i.id);
    if (idx == -1) {
      lostItems.add(i);
    } else {
      lostItems[idx] = i;
    }
    _commit(currentUser?.role == UserRole.admin ? 'Saved lost & found post "${i.title}"' : null);
  }

  void setLostStatus(LostItem i, LostStatus s) {
    _guard(Perm.editLost(currentUser, i));
    i.status = s;
    _commit(null);
  }

  void deleteLostItem(LostItem i) {
    _guard(Perm.editLost(currentUser, i));
    lostItems.remove(i);
    _commit('Deleted lost & found post "${i.title}"');
  }

  // --------------------------------------------------------- announcements
  void saveAnnouncement(Announcement a) {
    _guard(Perm.postAnnouncement(currentUser, a.societyId));
    final idx = announcements.indexWhere((x) => x.id == a.id);
    if (idx == -1) {
      announcements.add(a);
    } else {
      announcements[idx] = a;
    }
    _commit('Posted announcement "${a.title}"');
  }

  void deleteAnnouncement(Announcement a) {
    _guard(Perm.postAnnouncement(currentUser, a.societyId));
    announcements.remove(a);
    _commit('Deleted announcement "${a.title}"');
  }

  static String _hm(DateTime t) =>
      '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  static String _dur(Duration d) =>
      d.inHours > 0 ? '${d.inHours} h ${d.inMinutes % 60} min' : '${d.inMinutes} min';
}

import 'package:flutter/material.dart';

enum UserRole { student, faculty, society, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.faculty => 'Faculty focal person',
        UserRole.society => 'Society account',
        UserRole.admin => 'Administrator',
      };
}

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

class AppUser {
  String id;
  String name;
  String email;
  /// PBKDF2 hash string, see PasswordHasher. Never a plain password.
  String passwordHash;
  UserRole role;
  String? regNo;
  String department;
  String? societyId; // faculty focal / society account binding
  bool active;
  DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.regNo,
    this.department = '',
    this.societyId,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get initials {
    const titles = {'dr', 'dr.', 'mr', 'mr.', 'ms', 'ms.', 'mrs', 'mrs.', 'engr', 'engr.', 'prof', 'prof.'};
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => !titles.contains(p.toLowerCase()))
        .toList();
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'regNo': regNo,
        'department': department,
        'societyId': societyId,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        passwordHash: j['passwordHash'],
        role: UserRole.values.byName(j['role']),
        regNo: j['regNo'],
        department: j['department'] ?? '',
        societyId: j['societyId'],
        active: j['active'] ?? true,
        createdAt: _dt(j['createdAt']),
      );
}

enum SocietyStatus { active, suspended }

class Society {
  String id;
  String name;
  String shortName;
  String category;
  String description;
  String? logoAsset;
  int colorValue;
  String? focalFacultyId;
  String? accountUserId;
  int foundedYear;
  String contactEmail;
  SocietyStatus status;
  List<String> memberIds;
  List<String> pendingMemberIds;

  Society({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.description,
    this.logoAsset,
    required this.colorValue,
    this.focalFacultyId,
    this.accountUserId,
    required this.foundedYear,
    required this.contactEmail,
    this.status = SocietyStatus.active,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
  })  : memberIds = memberIds ?? [],
        pendingMemberIds = pendingMemberIds ?? [];

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'category': category,
        'description': description,
        'logoAsset': logoAsset,
        'colorValue': colorValue,
        'focalFacultyId': focalFacultyId,
        'accountUserId': accountUserId,
        'foundedYear': foundedYear,
        'contactEmail': contactEmail,
        'status': status.name,
        'memberIds': memberIds,
        'pendingMemberIds': pendingMemberIds,
      };

  factory Society.fromJson(Map<String, dynamic> j) => Society(
        id: j['id'],
        name: j['name'],
        shortName: j['shortName'],
        category: j['category'],
        description: j['description'],
        logoAsset: j['logoAsset'],
        colorValue: j['colorValue'],
        focalFacultyId: j['focalFacultyId'],
        accountUserId: j['accountUserId'],
        foundedYear: j['foundedYear'],
        contactEmail: j['contactEmail'],
        status: SocietyStatus.values.byName(j['status'] ?? 'active'),
        memberIds: List<String>.from(j['memberIds'] ?? const []),
        pendingMemberIds: List<String>.from(j['pendingMemberIds'] ?? const []),
      );
}

/// How attendance is captured for an event.
enum AttendanceMode {
  /// QR scan at the gate or in-app button, with time + location stamps on
  /// arrival and departure. Used for seminars, workshops, talks.
  checkInOut,

  /// Student marks attendance, the society's faculty focal person verifies.
  /// Used for society meetings.
  facultyVerified,
}

enum EventKind { seminar, workshop, meeting, competition, social, sports }

extension EventKindX on EventKind {
  String get label => switch (this) {
        EventKind.seminar => 'Seminar',
        EventKind.workshop => 'Workshop',
        EventKind.meeting => 'Meeting',
        EventKind.competition => 'Competition',
        EventKind.social => 'Social',
        EventKind.sports => 'Sports',
      };
  IconData get icon => switch (this) {
        EventKind.seminar => Icons.record_voice_over_outlined,
        EventKind.workshop => Icons.construction_outlined,
        EventKind.meeting => Icons.groups_2_outlined,
        EventKind.competition => Icons.emoji_events_outlined,
        EventKind.social => Icons.celebration_outlined,
        EventKind.sports => Icons.sports_cricket_outlined,
      };
}

enum EventStatus { published, cancelled }

class CampusEvent {
  String id;
  String societyId;
  String title;
  String description;
  EventKind kind;
  AttendanceMode mode;
  String venue;
  double lat;
  double lng;
  int radiusMeters;
  DateTime startAt;
  DateTime endAt;
  String createdBy;
  bool checkInOpen;
  String secret;
  int capacity;
  EventStatus status;
  List<String> registeredIds;
  String? advisorName; // e.g. seminar advisor issuing the check-in

  CampusEvent({
    required this.id,
    required this.societyId,
    required this.title,
    required this.description,
    required this.kind,
    required this.mode,
    required this.venue,
    required this.lat,
    required this.lng,
    this.radiusMeters = 150,
    required this.startAt,
    required this.endAt,
    required this.createdBy,
    this.checkInOpen = false,
    required this.secret,
    this.capacity = 0,
    this.status = EventStatus.published,
    List<String>? registeredIds,
    this.advisorName,
  }) : registeredIds = registeredIds ?? [];

  bool get isMeeting => mode == AttendanceMode.facultyVerified;
  bool isLive(DateTime now) =>
      status == EventStatus.published &&
      now.isAfter(startAt.subtract(const Duration(minutes: 30))) &&
      now.isBefore(endAt.add(const Duration(minutes: 30)));
  bool isPast(DateTime now) => now.isAfter(endAt.add(const Duration(minutes: 30)));
  bool isUpcoming(DateTime now) => now.isBefore(startAt.subtract(const Duration(minutes: 30)));

  Map<String, dynamic> toJson() => {
        'id': id,
        'societyId': societyId,
        'title': title,
        'description': description,
        'kind': kind.name,
        'mode': mode.name,
        'venue': venue,
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'createdBy': createdBy,
        'checkInOpen': checkInOpen,
        'secret': secret,
        'capacity': capacity,
        'status': status.name,
        'registeredIds': registeredIds,
        'advisorName': advisorName,
      };

  factory CampusEvent.fromJson(Map<String, dynamic> j) => CampusEvent(
        id: j['id'],
        societyId: j['societyId'],
        title: j['title'],
        description: j['description'],
        kind: EventKind.values.byName(j['kind']),
        mode: AttendanceMode.values.byName(j['mode']),
        venue: j['venue'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusMeters: j['radiusMeters'] ?? 150,
        startAt: DateTime.parse(j['startAt']),
        endAt: DateTime.parse(j['endAt']),
        createdBy: j['createdBy'],
        checkInOpen: j['checkInOpen'] ?? false,
        secret: j['secret'],
        capacity: j['capacity'] ?? 0,
        status: EventStatus.values.byName(j['status'] ?? 'published'),
        registeredIds: List<String>.from(j['registeredIds'] ?? const []),
        advisorName: j['advisorName'],
      );
}

enum CheckMethod { qr, app, code, marked, manual }

extension CheckMethodX on CheckMethod {
  String get label => switch (this) {
        CheckMethod.qr => 'QR at gate',
        CheckMethod.app => 'In-app button',
        CheckMethod.code => 'Session code',
        CheckMethod.marked => 'Self-marked',
        CheckMethod.manual => 'Added by staff',
      };
}

enum AttendanceStatus { recorded, pending, verified, rejected }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.recorded => 'Recorded',
        AttendanceStatus.pending => 'Awaiting verification',
        AttendanceStatus.verified => 'Verified',
        AttendanceStatus.rejected => 'Rejected',
      };
}

/// Stamped location. `null` coordinates mean the device could not provide one.
class GeoStamp {
  final double? lat;
  final double? lng;
  final double? accuracy;
  const GeoStamp({this.lat, this.lng, this.accuracy});
  bool get known => lat != null && lng != null;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'accuracy': accuracy};
  factory GeoStamp.fromJson(Map<String, dynamic>? j) => j == null
      ? const GeoStamp()
      : GeoStamp(
          lat: (j['lat'] as num?)?.toDouble(),
          lng: (j['lng'] as num?)?.toDouble(),
          accuracy: (j['accuracy'] as num?)?.toDouble(),
        );
}

class AttendanceRecord {
  String id;
  String eventId;
  String userId;
  DateTime checkInAt;
  GeoStamp checkInLoc;
  CheckMethod checkInMethod;
  DateTime? checkOutAt;
  GeoStamp? checkOutLoc;
  AttendanceStatus status;
  List<String> flags;
  String? reviewedBy;
  DateTime? reviewedAt;
  String? note;

  AttendanceRecord({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.checkInAt,
    required this.checkInLoc,
    required this.checkInMethod,
    this.checkOutAt,
    this.checkOutLoc,
    required this.status,
    List<String>? flags,
    this.reviewedBy,
    this.reviewedAt,
    this.note,
  }) : flags = flags ?? [];

  bool get isOpen => checkOutAt == null;
  Duration? get duration => checkOutAt?.difference(checkInAt);

  /// Human-friendly slip code an instructor can verify, e.g. LA-4K7Q-92XD.
  String get slipCode {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var h = 0x811c9dc5;
    for (final c in '$id$eventId$userId'.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    final b = StringBuffer();
    var x = h;
    for (var i = 0; i < 8; i++) {
      b.write(alphabet[x % alphabet.length]);
      x = (x ~/ alphabet.length) ^ (h >> (i + 3));
    }
    final s = b.toString();
    return 'LA-${s.substring(0, 4)}-${s.substring(4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'checkInAt': checkInAt.toIso8601String(),
        'checkInLoc': checkInLoc.toJson(),
        'checkInMethod': checkInMethod.name,
        'checkOutAt': checkOutAt?.toIso8601String(),
        'checkOutLoc': checkOutLoc?.toJson(),
        'status': status.name,
        'flags': flags,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'note': note,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'],
        eventId: j['eventId'],
        userId: j['userId'],
        checkInAt: DateTime.parse(j['checkInAt']),
        checkInLoc: GeoStamp.fromJson(j['checkInLoc']),
        checkInMethod: CheckMethod.values.byName(j['checkInMethod']),
        checkOutAt: _dt(j['checkOutAt']),
        checkOutLoc: j['checkOutLoc'] == null ? null : GeoStamp.fromJson(j['checkOutLoc']),
        status: AttendanceStatus.values.byName(j['status']),
        flags: List<String>.from(j['flags'] ?? const []),
        reviewedBy: j['reviewedBy'],
        reviewedAt: _dt(j['reviewedAt']),
        note: j['note'],
      );
}

enum RequestStatus { pending, approved, rejected }

class SocietyRequest {
  String id;
  String name;
  String shortName;
  String category;
  String mission;
  String activities;
  String presidentName;
  String presidentRegNo;
  String proposedAdvisor;
  String contactEmail;
  int foundingMembers;
  String submittedBy;
  DateTime submittedAt;
  RequestStatus status;
  String? adminNote;
  bool publishOnApproval;

  SocietyRequest({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.mission,
    required this.activities,
    required this.presidentName,
    required this.presidentRegNo,
    required this.proposedAdvisor,
    required this.contactEmail,
    required this.foundingMembers,
    required this.submittedBy,
    required this.submittedAt,
    this.status = RequestStatus.pending,
    this.adminNote,
    this.publishOnApproval = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'category': category,
        'mission': mission,
        'activities': activities,
        'presidentName': presidentName,
        'presidentRegNo': presidentRegNo,
        'proposedAdvisor': proposedAdvisor,
        'contactEmail': contactEmail,
        'foundingMembers': foundingMembers,
        'submittedBy': submittedBy,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'adminNote': adminNote,
        'publishOnApproval': publishOnApproval,
      };

  factory SocietyRequest.fromJson(Map<String, dynamic> j) => SocietyRequest(
        id: j['id'],
        name: j['name'],
        shortName: j['shortName'],
        category: j['category'],
        mission: j['mission'],
        activities: j['activities'],
        presidentName: j['presidentName'],
        presidentRegNo: j['presidentRegNo'],
        proposedAdvisor: j['proposedAdvisor'],
        contactEmail: j['contactEmail'],
        foundingMembers: j['foundingMembers'],
        submittedBy: j['submittedBy'],
        submittedAt: DateTime.parse(j['submittedAt']),
        status: RequestStatus.values.byName(j['status']),
        adminNote: j['adminNote'],
        publishOnApproval: j['publishOnApproval'] ?? true,
      );
}

enum LostType { lost, found }

enum LostStatus { open, resolved }

class LostItem {
  String id;
  LostType type;
  String title;
  String description;
  String category;
  String location;
  DateTime date;
  String postedBy;
  String contact;
  LostStatus status;
  DateTime createdAt;

  LostItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.postedBy,
    required this.contact,
    this.status = LostStatus.open,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const categories = [
    'Card / ID',
    'Electronics',
    'Bag',
    'Keys',
    'Books / Notes',
    'Clothing',
    'Bottle',
    'Other',
  ];

  static IconData iconFor(String c) => switch (c) {
        'Card / ID' => Icons.badge_outlined,
        'Electronics' => Icons.headphones_outlined,
        'Bag' => Icons.backpack_outlined,
        'Keys' => Icons.key_outlined,
        'Books / Notes' => Icons.menu_book_outlined,
        'Clothing' => Icons.checkroom_outlined,
        'Bottle' => Icons.local_drink_outlined,
        _ => Icons.category_outlined,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'date': date.toIso8601String(),
        'postedBy': postedBy,
        'contact': contact,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LostItem.fromJson(Map<String, dynamic> j) => LostItem(
        id: j['id'],
        type: LostType.values.byName(j['type']),
        title: j['title'],
        description: j['description'],
        category: j['category'],
        location: j['location'],
        date: DateTime.parse(j['date']),
        postedBy: j['postedBy'],
        contact: j['contact'],
        status: LostStatus.values.byName(j['status']),
        createdAt: _dt(j['createdAt']),
      );
}

class Announcement {
  String id;
  String? societyId; // null = campus-wide (admin)
  String title;
  String body;
  String authorId;
  DateTime createdAt;
  bool pinned;

  Announcement({
    required this.id,
    this.societyId,
    required this.title,
    required this.body,
    required this.authorId,
    required this.createdAt,
    this.pinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'societyId': societyId,
        'title': title,
        'body': body,
        'authorId': authorId,
        'createdAt': createdAt.toIso8601String(),
        'pinned': pinned,
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'],
        societyId: j['societyId'],
        title: j['title'],
        body: j['body'],
        authorId: j['authorId'],
        createdAt: DateTime.parse(j['createdAt']),
        pinned: j['pinned'] ?? false,
      );
}

class EventFeedback {
  String id;
  String eventId;
  String userId;
  int rating;
  String comment;
  DateTime createdAt;

  EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EventFeedback.fromJson(Map<String, dynamic> j) => EventFeedback(
        id: j['id'],
        eventId: j['eventId'],
        userId: j['userId'],
        rating: j['rating'],
        comment: j['comment'] ?? '',
        createdAt: DateTime.parse(j['createdAt']),
      );
}

class AuditEntry {
  final DateTime at;
  final String actorId;
  final String action;
  AuditEntry({required this.at, required this.actorId, required this.action});

  Map<String, dynamic> toJson() =>
      {'at': at.toIso8601String(), 'actorId': actorId, 'action': action};
  factory AuditEntry.fromJson(Map<String, dynamic> j) =>
      AuditEntry(at: DateTime.parse(j['at']), actorId: j['actorId'], action: j['action']);
}

class Venue {
  final String name;
  final double lat;
  final double lng;
  const Venue(this.name, this.lat, this.lng);
}

/// Air University, E-9 Islamabad. Coordinates are approximate per block.
const campusVenues = <Venue>[
  Venue('Main Auditorium', 33.71372, 73.02560),
  Venue('Seminar Hall, A-Block', 33.71410, 73.02495),
  Venue('Seminar Hall, B-Block', 33.71335, 73.02618),
  Venue('Computing Lab 3, C-Block', 33.71298, 73.02540),
  Venue('Central Library', 33.71440, 73.02588),
  Venue('Sports Complex', 33.71230, 73.02690),
  Venue('Cafeteria Lawn', 33.71355, 73.02470),
  Venue('Committee Room, Admin Block', 33.71395, 73.02640),
];

enum NoticeKind { attendance, membership, society, event, system }

class AppNotification {
  String id;
  String userId;
  NoticeKind kind;
  String title;
  String body;
  DateTime createdAt;
  bool read;
  String? refId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.refId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'kind': kind.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'refId': refId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        userId: j['userId'],
        kind: NoticeKind.values.byName(j['kind']),
        title: j['title'],
        body: j['body'],
        createdAt: DateTime.parse(j['createdAt']),
        read: j['read'] ?? false,
        refId: j['refId'],
      );
}

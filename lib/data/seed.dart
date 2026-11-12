import 'models.dart';

/// Demo data so every role has something real to look at on first launch.
/// Dates are generated relative to "now" so the live event is always live.
class SeedData {
  final List<AppUser> users;
  final List<Society> societies;
  final List<CampusEvent> events;
  final List<AttendanceRecord> attendance;
  final List<SocietyRequest> requests;
  final List<LostItem> lostItems;
  final List<Announcement> announcements;
  final List<EventFeedback> feedback;

  SeedData._(this.users, this.societies, this.events, this.attendance, this.requests,
      this.lostItems, this.announcements, this.feedback);

  factory SeedData.build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int dayOffset, int h, [int m = 0]) =>
        today.add(Duration(days: dayOffset, hours: h, minutes: m));

    // ---------------------------------------------------------------- users
    // Precomputed salted PBKDF2-SHA256 hashes of the demo passwords, so the
    // first launch does no hashing work on the UI thread.
    const pw = {
      'admin123': r'pbkdf2$2500$PmK8L77PUAEVBlSF50tkUA==$o1DvNHQe6vIzhMarCgtu1/+7CIbAFjMEF0rlZsehNA0=',
      'student123': r'pbkdf2$2500$YIxSdumKAC/PCfp4uNX2Og==$vH8EWO+lCf327c2MRJSVxzoIjyznZcgNJwPl/e8GuqY=',
      'faculty123': r'pbkdf2$2500$ZviX4kYmmuHD2BbV7Mzvig==$MmpnvqNXHF/DcKoxGNDxDsPEdL0cpw+P4dN5jV4wdjU=',
      'society123': r'pbkdf2$2500$7Q2SWPVnBK6NG8/bzHHFRg==$YrI9F8Lf++mtv2vqDeVSSrr6b7YPpnICtzAx1gOrhRQ=',
    };
    final users = <AppUser>[
      AppUser(
          id: 'u_admin',
          name: 'Developer Console',
          email: 'dev@loopair.app',
          passwordHash: pw['admin123']!,
          role: UserRole.admin,
          department: 'LoopAir Engineering'),
      // Students
      AppUser(
          id: 'u_s1',
          name: 'Hamza Tariq',
          email: 'student@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '221034',
          department: 'BS Computer Science'),
      AppUser(
          id: 'u_s2',
          name: 'Ayesha Siddiqui',
          email: 'ayesha@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '221187',
          department: 'BS Software Engineering'),
      AppUser(
          id: 'u_s3',
          name: 'Usman Khalid',
          email: 'usman@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '211452',
          department: 'BS Artificial Intelligence'),
      AppUser(
          id: 'u_s4',
          name: 'Fatima Noor',
          email: 'fatima@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '231009',
          department: 'BBA'),
      AppUser(
          id: 'u_s5',
          name: 'Bilal Ahmed',
          email: 'bilal@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '221320',
          department: 'BS Cyber Security'),
      AppUser(
          id: 'u_s6',
          name: 'Zainab Raza',
          email: 'zainab@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '231144',
          department: 'BS Computer Science'),
      AppUser(
          id: 'u_s7',
          name: 'Saad Mehmood',
          email: 'saad@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '211098',
          department: 'BE Mechatronics'),
      AppUser(
          id: 'u_s8',
          name: 'Mahnoor Ali',
          email: 'mahnoor@au.edu.pk',
          passwordHash: pw['student123']!,
          role: UserRole.student,
          regNo: '221276',
          department: 'BS Psychology'),
      // Faculty focal persons
      AppUser(
          id: 'u_f1',
          name: 'Dr. Saima Iqbal',
          email: 'faculty@au.edu.pk',
          passwordHash: pw['faculty123']!,
          role: UserRole.faculty,
          department: 'Department of Computer Science',
          societyId: 's_aucis'),
      AppUser(
          id: 'u_f2',
          name: 'Mr. Imran Haider',
          email: 'imran.haider@au.edu.pk',
          passwordHash: pw['faculty123']!,
          role: UserRole.faculty,
          department: 'Department of Creative Technologies',
          societyId: 's_gdgoc'),
      AppUser(
          id: 'u_f3',
          name: 'Dr. Muhammad Farooq',
          email: 'farooq@au.edu.pk',
          passwordHash: pw['faculty123']!,
          role: UserRole.faculty,
          department: 'Department of Humanities',
          societyId: 's_seerah'),
      AppUser(
          id: 'u_f4',
          name: 'Ms. Hira Javed',
          email: 'hira.javed@au.edu.pk',
          passwordHash: pw['faculty123']!,
          role: UserRole.faculty,
          department: 'Department of English',
          societyId: 's_debate'),
      // Society accounts
      AppUser(
          id: 'u_soc1',
          name: 'AUCIS Executive Council',
          email: 'aucis@au.edu.pk',
          passwordHash: pw['society123']!,
          role: UserRole.society,
          department: 'Society account',
          societyId: 's_aucis'),
      AppUser(
          id: 'u_soc2',
          name: 'GDGoC Air University Core Team',
          email: 'gdgoc@au.edu.pk',
          passwordHash: pw['society123']!,
          role: UserRole.society,
          department: 'Society account',
          societyId: 's_gdgoc'),
      AppUser(
          id: 'u_soc3',
          name: 'Seerah & Islamic Society',
          email: 'seerah@au.edu.pk',
          passwordHash: pw['society123']!,
          role: UserRole.society,
          department: 'Society account',
          societyId: 's_seerah'),
      AppUser(
          id: 'u_soc4',
          name: 'AU Debating Society',
          email: 'debate@au.edu.pk',
          passwordHash: pw['society123']!,
          role: UserRole.society,
          department: 'Society account',
          societyId: 's_debate'),
    ];

    // ------------------------------------------------------------ societies
    final societies = <Society>[
      Society(
        id: 's_aucis',
        name: 'Air University Computing & Innovation Society',
        shortName: 'AUCIS',
        category: 'Technology',
        description:
            'The flagship computing society of Air University. AUCIS runs coding bootcamps, '
            'the annual Softcom competition, industry talks and research circles for students '
            'across computing programmes.',
        logoAsset: 'assets/logos/aucis.jpg',
        colorValue: 0xFF1B6FB5,
        focalFacultyId: 'u_f1',
        accountUserId: 'u_soc1',
        foundedYear: 2012,
        contactEmail: 'aucis@au.edu.pk',
        memberIds: ['u_s1', 'u_s2', 'u_s3', 'u_s5', 'u_s6'],
        pendingMemberIds: ['u_s7'],
      ),
      Society(
        id: 's_gdgoc',
        name: 'Google Developer Groups on Campus',
        shortName: 'GDGoC AU',
        category: 'Technology',
        description:
            'A community of student developers learning Google technologies together: '
            'study jams, Solution Challenge teams, Flutter and Cloud workshops, and '
            'open speaker sessions with industry engineers.',
        logoAsset: 'assets/logos/gdgoc.jpeg',
        colorValue: 0xFF1E8E3E,
        focalFacultyId: 'u_f2',
        accountUserId: 'u_soc2',
        foundedYear: 2019,
        contactEmail: 'gdgoc@au.edu.pk',
        memberIds: ['u_s1', 'u_s3', 'u_s6', 'u_s8'],
        pendingMemberIds: ['u_s4'],
      ),
      Society(
        id: 's_seerah',
        name: 'Seerah & Islamic Society',
        shortName: 'SIS',
        category: 'Religious & Character',
        description:
            'Organises the annual Seerah-un-Nabi seminar series, Quran study circles and '
            'character-building sessions, in coordination with the Department of Humanities.',
        colorValue: 0xFF0F6B5C,
        focalFacultyId: 'u_f3',
        accountUserId: 'u_soc3',
        foundedYear: 2008,
        contactEmail: 'seerah@au.edu.pk',
        memberIds: ['u_s2', 'u_s4', 'u_s7'],
      ),
      Society(
        id: 's_debate',
        name: 'AU Debating Society',
        shortName: 'AUDS',
        category: 'Literary',
        description:
            'Parliamentary and Urdu debating, MUN delegations and public-speaking clinics. '
            'Represents Air University at national inter-varsity championships.',
        colorValue: 0xFF7A2E2E,
        focalFacultyId: 'u_f4',
        accountUserId: 'u_soc4',
        foundedYear: 2005,
        contactEmail: 'debate@au.edu.pk',
        memberIds: ['u_s4', 'u_s8'],
      ),
      Society(
        id: 's_media',
        name: 'Media & Photography Club',
        shortName: 'AUMC',
        category: 'Arts & Media',
        description:
            'Covers campus events, runs photo walks and short-film screenings, and maintains '
            'the official event photo archive.',
        colorValue: 0xFF3F3D56,
        foundedYear: 2014,
        contactEmail: 'media@au.edu.pk',
        memberIds: ['u_s6'],
      ),
      Society(
        id: 's_sports',
        name: 'Sports Society',
        shortName: 'AUSS',
        category: 'Sports',
        description:
            'Inter-department leagues in cricket, futsal, basketball and table tennis, and '
            'trials for university teams.',
        colorValue: 0xFFB45309,
        foundedYear: 2003,
        contactEmail: 'sports@au.edu.pk',
        memberIds: ['u_s5', 'u_s7'],
      ),
      Society(
        id: 's_ent',
        name: 'Entrepreneurship Society',
        shortName: 'AUES',
        category: 'Business',
        description:
            'Founder talks, pitch nights and a semester-long venture track in partnership '
            'with the university incubation centre.',
        colorValue: 0xFF4C5B8C,
        foundedYear: 2016,
        contactEmail: 'aues@au.edu.pk',
        memberIds: ['u_s4'],
      ),
      Society(
        id: 's_blood',
        name: 'Blood Donors Society',
        shortName: 'AUBDS',
        category: 'Community Service',
        description:
            'Maintains a campus donor registry and organises donation drives with partner '
            'hospitals in Islamabad.',
        colorValue: 0xFF9F1239,
        foundedYear: 2011,
        contactEmail: 'blood@au.edu.pk',
        status: SocietyStatus.active,
      ),
    ];

    // ---------------------------------------------------------------- events
    final h = now.hour;

    final events = <CampusEvent>[
      CampusEvent(
        id: 'e_seerah',
        societyId: 's_seerah',
        title: 'Seerah-un-Nabi Seminar 2026',
        description:
            'Annual Seerah seminar on "Leadership and Ethics in the Life of the Prophet ﷺ". '
            'Attendance is mandatory for first-year students of all departments; check in at '
            'the auditorium gate and check out when you leave.',
        kind: EventKind.seminar,
        mode: AttendanceMode.checkInOut,
        venue: 'Main Auditorium',
        lat: 33.71372,
        lng: 73.02560,
        radiusMeters: 150,
        startAt: today.add(Duration(hours: h, minutes: -20)),
        endAt: today.add(Duration(hours: h + 2)),
        createdBy: 'u_soc3',
        checkInOpen: true,
        secret: 'k3y-seerah-2026',
        capacity: 600,
        advisorName: 'Dr. Muhammad Farooq',
        registeredIds: ['u_s1', 'u_s2', 'u_s3', 'u_s4', 'u_s5', 'u_s6', 'u_s7', 'u_s8'],
      ),
      CampusEvent(
        id: 'e_aucis_meet',
        societyId: 's_aucis',
        title: 'AUCIS General Body Meeting',
        description:
            'Semester planning: Softcom 2026 committees, bootcamp schedule and budget review. '
            'Mark yourself present; Dr. Saima will verify the roll.',
        kind: EventKind.meeting,
        mode: AttendanceMode.facultyVerified,
        venue: 'Committee Room, Admin Block',
        lat: 33.71395,
        lng: 73.02640,
        startAt: today.add(Duration(hours: h, minutes: -10)),
        endAt: today.add(Duration(hours: h + 1)),
        createdBy: 'u_soc1',
        checkInOpen: true,
        secret: 'k3y-aucis-gbm',
        registeredIds: ['u_s1', 'u_s2', 'u_s3', 'u_s5', 'u_s6'],
      ),
      CampusEvent(
        id: 'e_flutter',
        societyId: 's_gdgoc',
        title: 'Build with Flutter: Hands-on Workshop',
        description:
            'From zero to a working cross-platform app in three hours. Bring a laptop with '
            'Flutter installed. Seats are limited to the lab capacity.',
        kind: EventKind.workshop,
        mode: AttendanceMode.checkInOut,
        venue: 'Computing Lab 3, C-Block',
        lat: 33.71298,
        lng: 73.02540,
        startAt: at(1, 11),
        endAt: at(1, 14),
        createdBy: 'u_soc2',
        secret: 'k3y-flutter',
        capacity: 45,
        registeredIds: ['u_s1', 'u_s3', 'u_s6'],
      ),
      CampusEvent(
        id: 'e_softcom',
        societyId: 's_aucis',
        title: 'Softcom Speed Programming Round',
        description:
            'Qualifier round for Softcom 2026. Teams of three, ICPC rules, four hours.',
        kind: EventKind.competition,
        mode: AttendanceMode.checkInOut,
        venue: 'Computing Lab 3, C-Block',
        lat: 33.71298,
        lng: 73.02540,
        startAt: at(3, 10),
        endAt: at(3, 14),
        createdBy: 'u_soc1',
        secret: 'k3y-softcom',
        capacity: 90,
      ),
      CampusEvent(
        id: 'e_debate',
        societyId: 's_debate',
        title: 'Parliamentary Debate Trials',
        description:
            'Trials for the national inter-varsity team. Motion released 15 minutes before rounds.',
        kind: EventKind.competition,
        mode: AttendanceMode.checkInOut,
        venue: 'Seminar Hall, A-Block',
        lat: 33.71410,
        lng: 73.02495,
        startAt: at(5, 14),
        endAt: at(5, 17),
        createdBy: 'u_soc4',
        secret: 'k3y-debate',
        capacity: 60,
      ),
      CampusEvent(
        id: 'e_gdg_meet',
        societyId: 's_gdgoc',
        title: 'Core Team Weekly Sync',
        description: 'Solution Challenge progress and study jam logistics.',
        kind: EventKind.meeting,
        mode: AttendanceMode.facultyVerified,
        venue: 'Central Library',
        lat: 33.71440,
        lng: 73.02588,
        startAt: at(2, 15),
        endAt: at(2, 16),
        createdBy: 'u_soc2',
        secret: 'k3y-gdg-sync',
      ),
      // Past
      CampusEvent(
        id: 'e_cloud',
        societyId: 's_gdgoc',
        title: 'Cloud Study Jam: Kick-off',
        description: 'Intro to Google Cloud skill badges and lab credits.',
        kind: EventKind.workshop,
        mode: AttendanceMode.checkInOut,
        venue: 'Seminar Hall, B-Block',
        lat: 33.71335,
        lng: 73.02618,
        startAt: at(-3, 11),
        endAt: at(-3, 13),
        createdBy: 'u_soc2',
        secret: 'k3y-cloud',
        capacity: 120,
      ),
      CampusEvent(
        id: 'e_aucis_old',
        societyId: 's_aucis',
        title: 'AUCIS Committee Heads Meeting',
        description: 'Assignment of committee heads for the semester.',
        kind: EventKind.meeting,
        mode: AttendanceMode.facultyVerified,
        venue: 'Committee Room, Admin Block',
        lat: 33.71395,
        lng: 73.02640,
        startAt: at(-2, 13),
        endAt: at(-2, 14),
        createdBy: 'u_soc1',
        secret: 'k3y-aucis-old',
      ),
      CampusEvent(
        id: 'e_ai_talk',
        societyId: 's_aucis',
        title: 'Industry Talk: Shipping AI Products',
        description: 'Engineers from a local AI startup on taking models to production.',
        kind: EventKind.seminar,
        mode: AttendanceMode.checkInOut,
        venue: 'Main Auditorium',
        lat: 33.71372,
        lng: 73.02560,
        startAt: at(-6, 10),
        endAt: at(-6, 12),
        createdBy: 'u_soc1',
        secret: 'k3y-ai-talk',
        capacity: 400,
      ),
    ];

    // ------------------------------------------------------------ attendance
    GeoStamp near(double lat, double lng, [double dLat = 0.00008, double dLng = 0.00005]) =>
        GeoStamp(lat: lat + dLat, lng: lng + dLng, accuracy: 12);

    final attendance = <AttendanceRecord>[
      // Live Seerah seminar: a few already inside
      AttendanceRecord(
          id: 'a1',
          eventId: 'e_seerah',
          userId: 'u_s2',
          checkInAt: now.subtract(const Duration(minutes: 18)),
          checkInLoc: near(33.71372, 73.02560),
          checkInMethod: CheckMethod.qr,
          status: AttendanceStatus.recorded),
      AttendanceRecord(
          id: 'a2',
          eventId: 'e_seerah',
          userId: 'u_s4',
          checkInAt: now.subtract(const Duration(minutes: 14)),
          checkInLoc: near(33.71372, 73.02560, -0.00005, 0.00002),
          checkInMethod: CheckMethod.app,
          status: AttendanceStatus.recorded),
      AttendanceRecord(
          id: 'a3',
          eventId: 'e_seerah',
          userId: 'u_s7',
          checkInAt: now.subtract(const Duration(minutes: 9)),
          checkInLoc: const GeoStamp(lat: 33.7189, lng: 73.0391, accuracy: 30),
          checkInMethod: CheckMethod.app,
          status: AttendanceStatus.recorded,
          flags: ['Outside venue (1.4 km away)']),
      // Live AUCIS meeting: pending faculty verification
      AttendanceRecord(
          id: 'a4',
          eventId: 'e_aucis_meet',
          userId: 'u_s2',
          checkInAt: now.subtract(const Duration(minutes: 6)),
          checkInLoc: near(33.71395, 73.02640),
          checkInMethod: CheckMethod.marked,
          status: AttendanceStatus.pending),
      AttendanceRecord(
          id: 'a5',
          eventId: 'e_aucis_meet',
          userId: 'u_s3',
          checkInAt: now.subtract(const Duration(minutes: 5)),
          checkInLoc: near(33.71395, 73.02640, 0.00003, -0.00004),
          checkInMethod: CheckMethod.marked,
          status: AttendanceStatus.pending),
      AttendanceRecord(
          id: 'a6',
          eventId: 'e_aucis_meet',
          userId: 'u_s5',
          checkInAt: now.subtract(const Duration(minutes: 3)),
          checkInLoc: const GeoStamp(),
          checkInMethod: CheckMethod.marked,
          status: AttendanceStatus.pending,
          flags: ['No location']),
      // Past AUCIS meeting
      AttendanceRecord(
          id: 'a7',
          eventId: 'e_aucis_old',
          userId: 'u_s1',
          checkInAt: at(-2, 13, 4),
          checkInLoc: near(33.71395, 73.02640),
          checkInMethod: CheckMethod.marked,
          checkOutAt: at(-2, 14, 1),
          checkOutLoc: near(33.71395, 73.02640),
          status: AttendanceStatus.verified,
          reviewedBy: 'u_f1',
          reviewedAt: at(-2, 14, 10)),
      AttendanceRecord(
          id: 'a8',
          eventId: 'e_aucis_old',
          userId: 'u_s6',
          checkInAt: at(-2, 13, 9),
          checkInLoc: near(33.71395, 73.02640),
          checkInMethod: CheckMethod.marked,
          status: AttendanceStatus.rejected,
          reviewedBy: 'u_f1',
          reviewedAt: at(-2, 14, 10),
          note: 'Not present at roll call'),
      // Past cloud study jam
      AttendanceRecord(
          id: 'a9',
          eventId: 'e_cloud',
          userId: 'u_s1',
          checkInAt: at(-3, 10, 56),
          checkInLoc: near(33.71335, 73.02618),
          checkInMethod: CheckMethod.qr,
          checkOutAt: at(-3, 13, 2),
          checkOutLoc: near(33.71335, 73.02618),
          status: AttendanceStatus.recorded),
      AttendanceRecord(
          id: 'a10',
          eventId: 'e_cloud',
          userId: 'u_s3',
          checkInAt: at(-3, 11, 5),
          checkInLoc: near(33.71335, 73.02618),
          checkInMethod: CheckMethod.qr,
          checkOutAt: at(-3, 11, 22),
          checkOutLoc: near(33.71335, 73.02618),
          status: AttendanceStatus.recorded,
          flags: ['Left early (17 min)']),
      AttendanceRecord(
          id: 'a11',
          eventId: 'e_cloud',
          userId: 'u_s6',
          checkInAt: at(-3, 11, 1),
          checkInLoc: near(33.71335, 73.02618),
          checkInMethod: CheckMethod.qr,
          status: AttendanceStatus.recorded,
          flags: ['No check-out recorded']),
      AttendanceRecord(
          id: 'a12',
          eventId: 'e_ai_talk',
          userId: 'u_s1',
          checkInAt: at(-6, 9, 52),
          checkInLoc: near(33.71372, 73.02560),
          checkInMethod: CheckMethod.qr,
          checkOutAt: at(-6, 12, 4),
          checkOutLoc: near(33.71372, 73.02560),
          status: AttendanceStatus.verified,
          reviewedBy: 'u_f1',
          reviewedAt: at(-6, 12, 30)),
      AttendanceRecord(
          id: 'a13',
          eventId: 'e_ai_talk',
          userId: 'u_s2',
          checkInAt: at(-6, 10, 3),
          checkInLoc: near(33.71372, 73.02560),
          checkInMethod: CheckMethod.app,
          checkOutAt: at(-6, 11, 58),
          checkOutLoc: near(33.71372, 73.02560),
          status: AttendanceStatus.recorded),
      AttendanceRecord(
          id: 'a14',
          eventId: 'e_ai_talk',
          userId: 'u_s5',
          checkInAt: at(-6, 10, 10),
          checkInLoc: near(33.71372, 73.02560),
          checkInMethod: CheckMethod.qr,
          checkOutAt: at(-6, 12, 0),
          checkOutLoc: near(33.71372, 73.02560),
          status: AttendanceStatus.recorded),
    ];

    // -------------------------------------------------------------- requests
    final requests = <SocietyRequest>[
      SocietyRequest(
        id: 'r1',
        name: 'Robotics & Embedded Systems Society',
        shortName: 'RESS',
        category: 'Technology',
        mission:
            'Give mechatronics and electrical students a place to build robots outside the '
            'syllabus and represent AU at national robotics competitions.',
        activities: 'Line-follower league, Arduino clinics, a robotics expo each spring.',
        presidentName: 'Saad Mehmood',
        presidentRegNo: '211098',
        proposedAdvisor: 'Engr. Waqas Anwar, Dept. of Mechatronics',
        contactEmail: 'saad@au.edu.pk',
        foundingMembers: 23,
        submittedBy: 'u_s7',
        submittedAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      SocietyRequest(
        id: 'r2',
        name: 'Mental Health Awareness Circle',
        shortName: 'MHAC',
        category: 'Community Service',
        mission: 'Peer-support sessions and awareness drives in partnership with the counselling office.',
        activities: 'Monthly listening circles, exam-stress workshops, awareness week.',
        presidentName: 'Mahnoor Ali',
        presidentRegNo: '221276',
        proposedAdvisor: 'Dr. Sadia Malik, Dept. of Psychology',
        contactEmail: 'mahnoor@au.edu.pk',
        foundingMembers: 17,
        submittedBy: 'u_s8',
        submittedAt: now.subtract(const Duration(hours: 20)),
      ),
    ];

    // ------------------------------------------------------------ lost/found
    final lostItems = <LostItem>[
      LostItem(
        id: 'l1',
        type: LostType.lost,
        title: 'Student ID card',
        description: 'Blue lanyard with AU card, name Bilal Ahmed. Probably near the cafeteria.',
        category: 'Card / ID',
        location: 'Cafeteria Lawn',
        date: now.subtract(const Duration(hours: 5)),
        postedBy: 'u_s5',
        contact: 'bilal@au.edu.pk',
      ),
      LostItem(
        id: 'l2',
        type: LostType.found,
        title: 'Black wireless earbuds case',
        description: 'Found on the third row after the AI talk. Handed to the auditorium desk.',
        category: 'Electronics',
        location: 'Main Auditorium',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        postedBy: 'u_s2',
        contact: 'Auditorium front desk',
      ),
      LostItem(
        id: 'l3',
        type: LostType.lost,
        title: 'Steel water bottle (green)',
        description: 'Has a GDG sticker on it.',
        category: 'Bottle',
        location: 'Computing Lab 3, C-Block',
        date: now.subtract(const Duration(days: 2)),
        postedBy: 'u_s6',
        contact: 'zainab@au.edu.pk',
      ),
      LostItem(
        id: 'l4',
        type: LostType.found,
        title: 'Set of keys with Honda keyring',
        description: 'Three keys, found near the library entrance.',
        category: 'Keys',
        location: 'Central Library',
        date: now.subtract(const Duration(days: 4)),
        postedBy: 'u_s3',
        contact: 'Library issue counter',
        status: LostStatus.resolved,
      ),
    ];

    final announcements = <Announcement>[
      Announcement(
        id: 'n1',
        title: 'Seerah seminar attendance counts toward class attendance',
        body:
            'Students attending the Seerah-un-Nabi seminar will be marked present in classes '
            'scheduled during the seminar, provided they have both a check-in and check-out '
            'stamp. Share your attendance slip code with your instructor.',
        authorId: 'u_admin',
        createdAt: now.subtract(const Duration(hours: 3)),
        pinned: true,
      ),
      Announcement(
        id: 'n2',
        societyId: 's_gdgoc',
        title: 'Flutter workshop: install before you come',
        body: 'Please install the Flutter SDK and Android Studio before tomorrow. Lab PCs are limited.',
        authorId: 'u_soc2',
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      Announcement(
        id: 'n3',
        societyId: 's_aucis',
        title: 'Softcom committee sign-ups close Friday',
        body: 'Register interest for Softcom 2026 committees through the general body meeting.',
        authorId: 'u_soc1',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    final feedback = <EventFeedback>[
      EventFeedback(
          id: 'fb1',
          eventId: 'e_ai_talk',
          userId: 'u_s2',
          rating: 5,
          comment: 'Very practical, would attend again.',
          createdAt: at(-6, 12, 20)),
      EventFeedback(
          id: 'fb2',
          eventId: 'e_ai_talk',
          userId: 'u_s5',
          rating: 4,
          comment: 'Q&A ran short.',
          createdAt: at(-6, 12, 40)),
      EventFeedback(
          id: 'fb3',
          eventId: 'e_cloud',
          userId: 'u_s1',
          rating: 4,
          comment: '',
          createdAt: at(-3, 13, 30)),
    ];

    return SeedData._(
        users, societies, events, attendance, requests, lostItems, announcements, feedback);
  }
}

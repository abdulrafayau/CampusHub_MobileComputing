import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../notifications/notifications_screen.dart';
import '../shell/home_shell.dart';
import 'admin_anomalies_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_events_screen.dart';
import 'admin_societies_screen.dart';
import 'admin_users_screen.dart';
import 'audit_log_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final students = store.users.where((x) => x.role == UserRole.student).length;
    final activeSoc = store.activeSocieties.length;
    final live = store.visibleEvents.where((e) => e.isLive(now)).length;
    final todayCheckins = store.attendance.where((r) => !r.checkInAt.isBefore(today)).length;
    final anomalies = store.anomalies;
    final high = anomalies.where((a) => a.severity == 'high').length;
    final pendingReq = store.requests.where((r) => r.status == RequestStatus.pending).length;
    final pendingVer = store.attendance.where((r) => r.status == AttendanceStatus.pending).length;

    // last 7 days check-ins
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final perDay = [
      for (final d in days)
        store.attendance
            .where((r) => !r.checkInAt.isBefore(d) && r.checkInAt.isBefore(d.add(const Duration(days: 1))))
            .length
            .toDouble()
    ];
    final labels = [for (final d in days) DateFormat('E').format(d).substring(0, 2).toUpperCase()];

    // leaderboard: check-ins per society
    final board = <(Society, int)>[
      for (final s in store.activeSocieties)
        (s, store.attendance.where((r) => store.eventById(r.eventId)?.societyId == s.id).length)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final maxBoard = board.isEmpty ? 1 : (board.first.$2 == 0 ? 1 : board.first.$2);

    final clean = store.attendance.isEmpty
        ? 1.0
        : store.attendance.where((r) => r.flags.isEmpty && r.status != AttendanceStatus.rejected).length /
            store.attendance.length;

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Row(children: [
            const IconBadge(Icons.terminal_rounded, bg: AppColors.navy, fg: Colors.white, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: AppText.heading),
                Text('Full access · audited', style: AppText.small),
              ]),
            ),
            CircleIconButton(Icons.history_rounded,
                tooltip: 'Audit log', onTap: () => push(context, const AuditLogScreen())),
            const SizedBox(width: 8),
            CircleIconButton(Icons.notifications_none_rounded,
                badgeCount: store.unreadCount, onTap: () => push(context, const NotificationsScreen())),
          ]),
        ),
        const SizedBox(height: 26),
        const Padding(padding: AppSpace.page, child: Headline('Campus at\n', 'a glance')),
        const SizedBox(height: 20),
        Padding(
          padding: AppSpace.page,
          child: GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _Kpi('Students', '$students', Icons.school_outlined, AppColors.sky, AppColors.skyInk,
                  () => push(context, const AdminUsersScreen())),
              _Kpi('Active societies', '$activeSoc', Icons.hub_outlined, AppColors.lavender,
                  AppColors.lavenderInk, () => push(context, const AdminSocietiesScreen())),
              _Kpi('Live events', '$live', Icons.sensors_rounded, AppColors.butter, AppColors.butterInk,
                  () => push(context, const AdminEventsScreen())),
              _Kpi('Check-ins today', '$todayCheckins', Icons.login_rounded, AppColors.sage, AppColors.sageInk,
                  () => push(context, const AdminAttendanceScreen())),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: AppSpace.page,
          child: AppCard(
            color: AppColors.navy,
            onTap: () => push(context, const AdminAnomaliesScreen()),
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${anomalies.length}', style: AppText.number.copyWith(color: Colors.white, fontSize: 40)),
                  Text('anomalies to review', style: AppText.body.copyWith(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (high > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(100)),
                        child: Text('$high high', style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text('$pendingVer awaiting faculty', style: AppText.small.copyWith(color: Colors.white54)),
                  ]),
                ]),
              ),
              const ArrowDot(size: 44),
            ]),
          ),
        ),
        const SectionHeader('Check-ins, last 7 days'),
        Padding(
          padding: AppSpace.page,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
            child: BarChart(values: perDay, labels: labels, height: 130),
          ),
        ),
        const SectionHeader('Data health'),
        Padding(
          padding: AppSpace.page,
          child: Row(children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
                child: Center(
                  child: ArcGauge(
                      value: clean,
                      center: '${(clean * 100).round()}%',
                      caption: 'clean records',
                      size: 150,
                      color: AppColors.sageInk),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                StatTile(
                    label: 'Society requests',
                    value: '$pendingReq',
                    caption: 'awaiting decision',
                    tone: pendingReq > 0 ? Tone.warning : Tone.neutral,
                    onTap: () => HomeShell.goTo(context, 2)),
                const SizedBox(height: 10),
                StatTile(
                    label: 'Total records',
                    value: '${store.attendance.length}',
                    caption: '${store.events.length} events',
                    onTap: () => push(context, const AdminAttendanceScreen())),
              ]),
            ),
          ]),
        ),
        const SectionHeader('Most active societies'),
        Padding(
          padding: AppSpace.page,
          child: AppCard(
            child: Column(children: [
              for (final b in board.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    SocietyAvatar(b.$1, size: 32),
                    const SizedBox(width: 10),
                    SizedBox(width: 74, child: Text(b.$1.shortName, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: b.$2 / maxBoard,
                          minHeight: 10,
                          backgroundColor: AppColors.sunken,
                          color: b.$1.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 24, child: Text('${b.$2}', style: AppText.bodyStrong, textAlign: TextAlign.end)),
                  ]),
                ),
            ]),
          ),
        ),
        SectionHeader('Recent changes',
            actionLabel: 'Audit log', onAction: () => push(context, const AuditLogScreen())),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            for (final a in store.audit.take(5))
              ListRow(
                leading: const IconBadge(Icons.history_rounded, size: 34),
                title: a.action,
                subtitle: '${store.userById(a.actorId)?.name ?? a.actorId} · ${Fmt.ago(a.at)}',
              ),
          ]),
        ),
      ]),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color bg, ink;
  final VoidCallback onTap;
  const _Kpi(this.label, this.value, this.icon, this.bg, this.ink, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: ink, size: 20),
                const Spacer(),
                Icon(Icons.north_east_rounded, color: ink, size: 16),
              ]),
              const Spacer(),
              Text(value, style: AppText.number),
              Text(label, style: AppText.small.copyWith(color: ink)),
            ]),
          ),
        ),
      );
}

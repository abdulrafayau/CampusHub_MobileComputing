import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../events/attendees_screen.dart';
import '../events/event_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/home_shell.dart';
import '../societies/society_detail_screen.dart';

class FacultyHome extends StatelessWidget {
  const FacultyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final s = store.societyById(u.societyId);
    final now = DateTime.now();
    final events = s == null ? <CampusEvent>[] : store.eventsForSociety(s.id);
    final recs = store.attendance.where((r) => events.any((e) => e.id == r.eventId)).toList();
    final pending = recs.where((r) => r.status == AttendanceStatus.pending).length;
    final reviewed = recs.where((r) => r.status == AttendanceStatus.verified || r.status == AttendanceStatus.rejected).length;
    final verifiable = recs.where((r) => r.status != AttendanceStatus.recorded).length;
    final today = events.where((e) => e.isLive(now) || (e.isUpcoming(now) && e.startAt.difference(now).inDays < 7)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Row(children: [
            UserAvatar(u, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: AppText.heading),
                Text('Focal person · ${s?.shortName ?? 'No society'}', style: AppText.small),
              ]),
            ),
            CircleIconButton(Icons.notifications_none_rounded,
                badgeCount: store.unreadCount, onTap: () => push(context, const NotificationsScreen())),
          ]),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: AppSpace.page,
          child: pending > 0
              ? Headline('$pending student${pending == 1 ? '' : 's'}\n', 'waiting on you')
              : const Headline('All caught up.\n', 'Nothing to verify.'),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: AppSpace.page,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(children: [
              ArcGauge(
                value: verifiable == 0 ? 1 : reviewed / verifiable,
                center: verifiable == 0 ? '—' : '${(reviewed / verifiable * 100).round()}%',
                caption: 'of meeting marks reviewed',
                size: 210,
                color: AppColors.sageInk,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => HomeShell.goTo(context, 1),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(pending > 0 ? 'Review $pending pending' : 'Open verification queue'),
              ),
            ]),
          ),
        ),
        if (s != null) ...[
          const SectionHeader('Your society'),
          Padding(
            padding: AppSpace.page,
            child: AppCard(
              onTap: () => push(context, SocietyDetailScreen(societyId: s.id)),
              child: Row(children: [
                SocietyAvatar(s, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: AppText.bodyStrong, maxLines: 2),
                    const SizedBox(height: 2),
                    Text('${s.memberIds.length} members · ${events.length} events', style: AppText.small),
                  ]),
                ),
                const ArrowDot(color: AppColors.sunken),
              ]),
            ),
          ),
        ],
        const SectionHeader('This week'),
        if (today.isEmpty)
          const Padding(
            padding: AppSpace.page,
            child: AppCard(
              child: EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No sessions this week',
                  message: 'Meetings created by your society appear here.'),
            ),
          ),
        for (final e in today)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: EventTile(
              e,
              onTap: () => push(context,
                  e.isMeeting ? AttendeesScreen(eventId: e.id) : EventDetailScreen(eventId: e.id)),
            ),
          ),
      ]),
    );
  }
}

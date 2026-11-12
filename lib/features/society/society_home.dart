import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../announcements/announcements_screen.dart';
import '../attendance/live_session_screen.dart';
import '../events/event_detail_screen.dart';
import '../events/event_form_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/home_shell.dart';
import '../societies/society_detail_screen.dart';

class SocietyHome extends StatelessWidget {
  const SocietyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final s = store.societyById(u.societyId);
    if (s == null) {
      return const SafeArea(
        child: EmptyState(
            icon: Icons.link_off_rounded,
            title: 'No society linked',
            message: 'Ask the administrator to link this account to a society.'),
      );
    }
    final now = DateTime.now();
    final events = store.eventsForSociety(s.id).where((e) => e.status == EventStatus.published).toList();
    final live = events.where((e) => e.isLive(now)).toList();
    final upcoming = events.where((e) => e.isUpcoming(now)).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
    final recs = store.attendance.where((r) => events.any((e) => e.id == r.eventId)).toList();

    // check-ins per event over the last 6 events
    final recent = events.where((e) => !e.isUpcoming(now)).take(6).toList().reversed.toList();
    final values = [for (final e in recent) store.recordsForEvent(e.id).length.toDouble()];
    final labels = [for (final e in recent) '${e.startAt.day}/${e.startAt.month}'];
    final ratings = events.map((e) => store.averageRating(e.id)).whereType<double>().toList();
    final avg = ratings.isEmpty ? null : ratings.reduce((a, b) => a + b) / ratings.length;

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Row(children: [
            SocietyAvatar(s, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.shortName, style: AppText.heading),
                Text('Society account', style: AppText.small),
              ]),
            ),
            CircleIconButton(Icons.visibility_outlined,
                tooltip: 'Public page', onTap: () => push(context, SocietyDetailScreen(societyId: s.id))),
            const SizedBox(width: 8),
            CircleIconButton(Icons.notifications_none_rounded,
                badgeCount: store.unreadCount, onTap: () => push(context, const NotificationsScreen())),
          ]),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: AppSpace.page,
          child: live.isNotEmpty
              ? Headline('${live.first.title}\n', 'is live now', size: 26)
              : const Headline('Run your next\n', 'great event'),
        ),
        const SizedBox(height: 18),
        if (live.isNotEmpty)
          Padding(
            padding: AppSpace.page,
            child: AppCard(
              color: AppColors.navy,
              onTap: () => push(context,
                  live.first.isMeeting ? EventDetailScreen(eventId: live.first.id) : LiveSessionScreen(eventId: live.first.id)),
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const IconBadge(Icons.qr_code_2_rounded, bg: Colors.white, fg: AppColors.navy, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(live.first.isMeeting ? 'Open the meeting roll' : 'Show check-in QR',
                        style: AppText.heading.copyWith(color: Colors.white)),
                    Text('${store.recordsForEvent(live.first.id).length} checked in so far',
                        style: AppText.small.copyWith(color: Colors.white60)),
                  ]),
                ),
                const ArrowDot(),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: AppSpace.page,
          child: Row(children: [
            Expanded(
              child: PastelTile(
                title: 'New event',
                caption: 'Seminar, meeting…',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.sky,
                ink: AppColors.skyInk,
                height: 130,
                onTap: () => push(context, EventFormScreen(societyId: s.id)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PastelTile(
                title: 'Post notice',
                caption: 'To all members',
                icon: Icons.campaign_outlined,
                color: AppColors.butter,
                ink: AppColors.butterInk,
                height: 130,
                onTap: () => push(context, AnnouncementFormScreen(societyId: s.id)),
              ),
            ),
          ]),
        ),
        const SectionHeader('At a glance'),
        Padding(
          padding: AppSpace.page,
          child: Row(children: [
            Expanded(child: StatTile(label: 'Members', value: '${s.memberIds.length}', icon: Icons.groups_outlined,
                caption: s.pendingMemberIds.isEmpty ? null : '${s.pendingMemberIds.length} waiting',
                onTap: () => HomeShell.goTo(context, 2))),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Check-ins', value: '${recs.length}', icon: Icons.login_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile(
                    label: 'Rating',
                    value: avg == null ? '—' : avg.toStringAsFixed(1),
                    icon: Icons.star_outline_rounded)),
          ]),
        ),
        if (values.isNotEmpty) ...[
          const SectionHeader('Turnout by event'),
          Padding(
            padding: AppSpace.page,
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: BarChart(values: values, labels: labels, height: 120),
            ),
          ),
        ],
        SectionHeader('Upcoming', actionLabel: 'All events', onAction: () => HomeShell.goTo(context, 1)),
        if (upcoming.isEmpty)
          const Padding(
            padding: AppSpace.page,
            child: AppCard(
                child: EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'Nothing scheduled',
                    message: 'Create an event and members get notified.')),
          ),
        for (final e in upcoming.take(3))
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: EventTile(e, onTap: () => push(context, EventDetailScreen(eventId: e.id))),
          ),
      ]),
    );
  }
}

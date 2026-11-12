import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../announcements/announcements_screen.dart';
import '../attendance/check_in_flow.dart';
import '../attendance/my_attendance_screen.dart';
import '../attendance/slip_screen.dart';
import '../events/event_detail_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/home_shell.dart';
import '../societies/society_request_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  late final Timer _tick;
  @override
  void initState() {
    super.initState();
    // refresh the "inside for N min" counter
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final now = DateTime.now();
    final open = store.openRecordFor(u.id);
    final openEvent = open == null ? null : store.eventById(open.eventId);
    final mySocs = store.societies.where((s) => s.memberIds.contains(u.id)).map((s) => s.id).toSet();
    final live = store.visibleEvents
        .where((e) => e.isLive(now) && (e.mode == AttendanceMode.checkInOut || mySocs.contains(e.societyId)))
        .toList();
    final upcoming = store.visibleEvents
        .where((e) => e.isUpcoming(now) && (e.registeredIds.contains(u.id) || mySocs.contains(e.societyId)))
        .take(3)
        .toList();
    final notes = store.announcementsFor(u).take(2).toList();
    final records = store.recordsForUser(u.id);
    final pending = records.where((r) => r.status == AttendanceStatus.pending).length;
    final myLost = store.lostItems.where((i) => i.status == LostStatus.open).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: () async => setState(() {}),
        child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
          // ---- top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
            child: Row(children: [
              UserAvatar(u, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: AppText.heading),
                  Text(u.department, style: AppText.small),
                ]),
              ),
              CircleIconButton(Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  badgeCount: store.unreadCount,
                  onTap: () => push(context, const NotificationsScreen())),
            ]),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: AppSpace.page,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: AppText.small),
              const SizedBox(height: 6),
              openEvent != null
                  ? const Headline('You\'re checked in.\n', 'Don\'t forget to leave.')
                  : live.isNotEmpty
                      ? Headline('${live.length} session${live.length == 1 ? ' is' : 's are'}\n', 'live right now')
                      : const Headline('Nothing live.\n', 'Plan your week.'),
            ]),
          ),
          const SizedBox(height: 20),

          // ---- active session
          if (open != null && openEvent != null)
            Padding(
              padding: AppSpace.page,
              child: _ActiveSessionCard(record: open, event: openEvent),
            ),

          // ---- live now
          if (live.where((e) => e.id != openEvent?.id).isNotEmpty) ...[
            SectionHeader('Live now', actionLabel: 'All events', onAction: () => HomeShell.goTo(context, 1)),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSpace.page,
                itemCount: live.where((e) => e.id != openEvent?.id).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _LiveCard(event: live.where((e) => e.id != openEvent?.id).toList()[i]),
              ),
            ),
          ],

          // ---- quick actions
          const SectionHeader('Quick actions'),
          Padding(
            padding: AppSpace.page,
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: PastelTile(
                    title: 'My attendance',
                    caption: '${records.length} sessions',
                    badge: pending > 0 ? '$pending pending' : null,
                    icon: Icons.insights_rounded,
                    color: AppColors.lavender,
                    ink: AppColors.lavenderInk,
                    onTap: () => push(context, const MyAttendanceScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PastelTile(
                    title: 'Lost & found',
                    caption: '$myLost open posts',
                    icon: Icons.travel_explore_rounded,
                    color: AppColors.butter,
                    ink: AppColors.butterInk,
                    onTap: () => push(context, const LostFoundScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: PastelTile(
                    title: 'Notice board',
                    caption: '${store.announcementsFor(u).length} notices',
                    icon: Icons.campaign_outlined,
                    color: AppColors.sage,
                    ink: AppColors.sageInk,
                    onTap: () => push(context, const AnnouncementsScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PastelTile(
                    title: 'Start a society',
                    caption: 'Send a proposal',
                    icon: Icons.add_business_outlined,
                    color: AppColors.blush,
                    ink: AppColors.blushInk,
                    onTap: () => push(context, const SocietyRequestScreen()),
                  ),
                ),
              ]),
            ]),
          ),

          // ---- notices
          if (notes.isNotEmpty) ...[
            SectionHeader('Notice board',
                actionLabel: 'See all', onAction: () => push(context, const AnnouncementsScreen())),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: AnnouncementCard(n),
              ),
          ],

          // ---- upcoming
          SectionHeader('Coming up for you',
              actionLabel: 'Calendar', onAction: () => HomeShell.goTo(context, 1)),
          if (upcoming.isEmpty)
            const Padding(
              padding: AppSpace.page,
              child: AppCard(
                child: EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No upcoming events',
                    message: 'Join a society or register for an event to see it here.'),
              ),
            ),
          for (final e in upcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: EventTile(e, onTap: () => push(context, EventDetailScreen(eventId: e.id))),
            ),
        ]),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final AttendanceRecord record;
  final CampusEvent event;
  const _ActiveSessionCard({required this.record, required this.event});

  @override
  Widget build(BuildContext context) {
    final inside = DateTime.now().difference(record.checkInAt);
    final progress = (DateTime.now().difference(event.startAt).inSeconds /
            event.endAt.difference(event.startAt).inSeconds)
        .clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const LiveDot(color: Color(0xFF6EE7A8)),
          const SizedBox(width: 6),
          Text('Inside for ${Fmt.duration(inside)}',
              style: AppText.small.copyWith(color: const Color(0xFF6EE7A8), fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('In at ${Fmt.time(record.checkInAt)}',
              style: AppText.small.copyWith(color: Colors.white54)),
        ]),
        const SizedBox(height: 14),
        Text(event.title, style: AppText.title.copyWith(color: Colors.white)),
        const SizedBox(height: 4),
        Text('${event.venue} · ends ${Fmt.time(event.endAt)}',
            style: AppText.small.copyWith(color: Colors.white60)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.navySoft,
            color: const Color(0xFF9CC3EE),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: AppColors.navy, minimumSize: const Size(0, 50)),
              onPressed: () => performCheckOut(context, record),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Leave'),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => push(context, SlipScreen(recordId: record.id)),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.receipt_long_outlined, color: Colors.white),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final CampusEvent event;
  const _LiveCard({required this.event});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.societyById(event.societyId);
    final mine = store.recordFor(event.id, store.currentUser!.id);
    return SizedBox(
      width: 270,
      child: AppCard(
        onTap: () => push(context, EventDetailScreen(eventId: event.id)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SocietyAvatar(s, size: 34),
            const SizedBox(width: 10),
            Expanded(child: Text(s?.shortName ?? '', style: AppText.small.copyWith(fontWeight: FontWeight.w700))),
            const Pill('Live', tone: Tone.live, dot: true),
          ]),
          const SizedBox(height: 12),
          Text(event.title, style: AppText.heading, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(event.venue, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: mine != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Pill(mine.isOpen ? 'You\'re inside' : 'Attended · ${mine.status.label}',
                        tone: mine.isOpen ? Tone.live : toneForStatus(mine.status), icon: Icons.check_rounded),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                    onPressed: !event.checkInOpen
                        ? null
                        : () => performCheckIn(
                            context, event, event.isMeeting ? CheckMethod.marked : CheckMethod.app),
                    child: Text(!event.checkInOpen
                        ? 'Check-in not open'
                        : event.isMeeting
                            ? 'Mark present'
                            : 'Check in'),
                  ),
          ),
        ]),
      ),
    );
  }
}

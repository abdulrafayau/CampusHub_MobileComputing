import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../announcements/announcements_screen.dart';
import '../events/event_detail_screen.dart';

class SocietyDetailScreen extends StatelessWidget {
  final String societyId;
  const SocietyDetailScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.societyById(societyId);
    if (s == null) return const Scaffold(body: Center(child: Text('Society not found')));
    final u = store.currentUser!;
    final now = DateTime.now();
    final events = store.eventsForSociety(s.id).where((e) => e.status == EventStatus.published).toList();
    final upcoming = events.where((e) => !e.isPast(now)).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
    final past = events.where((e) => e.isPast(now)).take(3).toList();
    final focal = store.userById(s.focalFacultyId);
    final isMember = s.memberIds.contains(u.id);
    final isPending = s.pendingMemberIds.contains(u.id);
    final notes = store.announcements.where((a) => a.societyId == s.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final totalCheckins = store.attendance.where((r) => events.any((e) => e.id == r.eventId)).length;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: s.color,
          foregroundColor: Colors.white,
          expandedHeight: 210,
          flexibleSpace: FlexibleSpaceBar(
            background: ColoredBox(
              color: s.color,
              child: Stack(children: [
                Positioned(
                  right: -40,
                  top: -30,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 22,
                  right: 20,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                      child: SocietyAvatar(s, size: 72),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.shortName, style: AppText.title.copyWith(color: Colors.white)),
                        Text('${s.category} · since ${s.foundedYear}',
                            style: AppText.small.copyWith(color: Colors.white70)),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: AppText.title),
              const SizedBox(height: 10),
              Text(s.description, style: AppText.body.copyWith(fontSize: 15)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: StatTile(label: 'Members', value: '${s.memberIds.length}')),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Events', value: '${events.length}')),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Check-ins', value: '$totalCheckins')),
              ]),
              if (u.role == UserRole.student) ...[
                const SizedBox(height: 16),
                if (isMember)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirm(context,
                          title: 'Leave ${s.shortName}?',
                          message: 'You will stop receiving its notices. Your attendance history stays.',
                          confirmLabel: 'Leave',
                          destructive: true);
                      if (ok) store.leaveSociety(s);
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    label: const Text('Member · tap to leave'),
                  )
                else if (isPending)
                  OutlinedButton.icon(
                    onPressed: () => store.leaveSociety(s),
                    icon: const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 20),
                    label: const Text('Request sent · tap to withdraw'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      store.requestJoin(s);
                      toast(context, 'Request sent to ${s.shortName}');
                    },
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Request to join'),
                  ),
              ],
              const SizedBox(height: 22),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(children: [
                  InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Faculty focal person',
                      value: focal?.name ?? 'Not assigned yet'),
                  if (focal != null)
                    InfoRow(icon: Icons.apartment_outlined, label: 'Department', value: focal.department),
                  InfoRow(icon: Icons.mail_outline_rounded, label: 'Contact', value: s.contactEmail),
                ]),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Notices', style: AppText.heading.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                for (final n in notes.take(2))
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: AnnouncementCard(n)),
              ],
              const SizedBox(height: 22),
              Text('Upcoming', style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 10),
              if (upcoming.isEmpty) Text('Nothing scheduled right now.', style: AppText.body),
              for (final e in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EventTile(e, onTap: () => push(context, EventDetailScreen(eventId: e.id))),
                ),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Recent', style: AppText.heading.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                for (final e in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EventTile(e, onTap: () => push(context, EventDetailScreen(eventId: e.id))),
                  ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

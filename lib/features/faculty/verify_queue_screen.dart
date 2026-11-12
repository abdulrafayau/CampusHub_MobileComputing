import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../events/attendees_screen.dart';
import '../shell/home_shell.dart';

/// Every pending attendance record for the faculty member's society,
/// grouped by event, with one-tap Present / Not present.
class VerifyQueueScreen extends StatelessWidget {
  const VerifyQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final events = store.events.where((e) => e.societyId == u.societyId).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    final groups = <CampusEvent, List<AttendanceRecord>>{};
    for (final e in events) {
      final p = store.recordsForEvent(e.id).where((r) => r.status == AttendanceStatus.pending).toList();
      if (p.isNotEmpty) groups[e] = p;
    }

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        const SizedBox(height: 12),
        const PageHeader(light: 'Verification\n', bold: 'queue'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text('Confirm who was actually in the room. Verified records become valid class slips.',
              style: AppText.body),
        ),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Queue is empty',
                message: 'New attendance marks from your society\'s meetings will appear here.'),
          ),
        for (final entry in groups.entries) ...[
          SectionHeader(entry.key.title,
              actionLabel: 'Open',
              onAction: () => push(context, AttendeesScreen(eventId: entry.key.id))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text('${Fmt.range(entry.key.startAt, entry.key.endAt)} · ${entry.key.venue}',
                style: AppText.small),
          ),
          const SizedBox(height: 10),
          for (final r in entry.value)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _QueueCard(record: r),
            ),
        ],
      ]),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final AttendanceRecord record;
  const _QueueCard({required this.record});
  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final u = store.userById(record.userId);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          UserAvatar(u, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u?.name ?? 'Unknown', style: AppText.bodyStrong),
              Text('${u?.regNo} · marked ${Fmt.time(record.checkInAt)}', style: AppText.small),
            ]),
          ),
        ]),
        if (record.flags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(12)),
            child: Text(record.flags.join(' · '),
                style: AppText.small.copyWith(color: AppColors.warning)),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: AppColors.danger),
              onPressed: () => guarded(
                  context, () => store.review(record, false, note: 'Not present at roll call'),
                  success: 'Marked not present'),
              child: const Text('Not present'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: AppColors.success),
              onPressed: () => guarded(context, () => store.review(record, true), success: 'Verified'),
              child: const Text('Present'),
            ),
          ),
        ]),
      ]),
    );
  }
}

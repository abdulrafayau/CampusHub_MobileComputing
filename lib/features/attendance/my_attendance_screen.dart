import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import 'slip_screen.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});
  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final all = store.recordsForUser(u.id);
    final verified = all.where((r) => r.status == AttendanceStatus.verified).length;
    final pending = all.where((r) => r.status == AttendanceStatus.pending).length;
    final ok = all.where((r) => r.status != AttendanceStatus.rejected && r.flags.isEmpty).length;
    final rate = all.isEmpty ? 0.0 : ok / all.length;
    final hours = store.activityHours(u.id);
    final list = all.where((r) => switch (_filter) {
          'Verified' => r.status == AttendanceStatus.verified,
          'Pending' => r.status == AttendanceStatus.pending,
          'Flagged' => r.flags.isNotEmpty || r.status == AttendanceStatus.rejected,
          _ => true,
        }).toList();

    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        const PageHeader(eyebrow: 'Your record', light: 'Attendance\n', bold: 'history'),
        const SizedBox(height: 16),
        Padding(
          padding: AppSpace.page,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(children: [
              ArcGauge(
                  value: rate,
                  center: '${(rate * 100).round()}%',
                  caption: 'clean attendance',
                  size: 200),
              const SizedBox(height: 12),
              Row(children: [
                _Mini('${all.length}', 'Sessions'),
                _Mini('$verified', 'Verified'),
                _Mini('$pending', 'Pending'),
                _Mini('${hours.inHours}h ${hours.inMinutes % 60}m', 'Activity time'),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        FilterChips<String>(
          values: const ['All', 'Verified', 'Pending', 'Flagged'],
          selected: _filter,
          label: (v) => v,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing here yet',
              message: 'Check in to an event or mark a meeting to start your record.'),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: RecordCard(record: r, onTap: () => push(context, SlipScreen(recordId: r.id))),
          ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String v, l;
  const _Mini(this.v, this.l);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(v, style: AppText.heading),
          const SizedBox(height: 2),
          Text(l, style: AppText.small.copyWith(fontSize: 11.5), textAlign: TextAlign.center),
        ]),
      );
}

class RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap;
  final bool showUser;
  const RecordCard({super.key, required this.record, this.onTap, this.showUser = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final r = record;
    final e = store.eventById(r.eventId);
    final u = store.userById(r.userId);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        showUser ? UserAvatar(u, size: 42) : SocietyAvatar(store.societyById(e?.societyId), size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(showUser ? (u?.name ?? 'Unknown') : (e?.title ?? 'Event removed'),
                style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${Fmt.day(r.checkInAt)} · ${Fmt.time(r.checkInAt)}'
              '${r.checkOutAt != null ? ' – ${Fmt.time(r.checkOutAt!)}' : ''}',
              style: AppText.small,
            ),
            if (r.flags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.flags.join(' · '),
                  style: AppText.small.copyWith(color: AppColors.warning, fontSize: 11.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Pill(r.isOpen && e?.isMeeting != true && r.status == AttendanceStatus.recorded ? 'Inside' : r.status.label,
            tone: r.isOpen && r.status == AttendanceStatus.recorded ? Tone.live : toneForStatus(r.status)),
      ]),
    );
  }
}

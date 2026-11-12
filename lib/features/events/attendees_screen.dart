import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';
import '../attendance/my_attendance_screen.dart';
import '../attendance/slip_screen.dart';

class AttendeesScreen extends StatefulWidget {
  final String eventId;
  const AttendeesScreen({super.key, required this.eventId});
  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  String _filter = 'All';

  void _exportCsv(AppStore store, CampusEvent e, List<AttendanceRecord> recs) {
    final b = StringBuffer('Name,Reg No,Department,Check in,Check-in location,Method,Check out,'
        'Check-out location,Minutes,Status,Flags,Slip code\n');
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    for (final r in recs) {
      final u = store.userById(r.userId);
      b.writeln([
        q(u?.name ?? ''),
        u?.regNo ?? '',
        q(u?.department ?? ''),
        r.checkInAt.toIso8601String(),
        q(Fmt.coord(r.checkInLoc.lat, r.checkInLoc.lng)),
        r.checkInMethod.label,
        r.checkOutAt?.toIso8601String() ?? '',
        q(Fmt.coord(r.checkOutLoc?.lat, r.checkOutLoc?.lng)),
        r.duration?.inMinutes ?? '',
        r.status.label,
        q(r.flags.join('; ')),
        r.slipCode,
      ].join(','));
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    toast(context, 'CSV for ${recs.length} records copied. Paste into Excel or Sheets.');
  }

  Future<void> _reject(AppStore store, AttendanceRecord r) async {
    final c = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reject attendance'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason (shown to the student)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(d, c.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (note == null || !mounted) return;
    guarded(context, () => store.review(r, false, note: note.isEmpty ? 'Not present at roll call' : note),
        success: 'Marked as not present');
  }

  Future<void> _addManual(AppStore store, CampusEvent e) async {
    final students = store.users
        .where((u) => u.role == UserRole.student && store.recordFor(e.id, u.id) == null)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final picked = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, sc) => ListView(controller: sc, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Add a student manually', style: AppText.title),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('For students without a phone. Recorded as "Added by staff" and verified.',
                style: AppText.small),
          ),
          for (final u in students)
            ListRow(
              leading: UserAvatar(u, size: 38),
              title: u.name,
              subtitle: '${u.regNo} · ${u.department}',
              onTap: () => Navigator.pop(c, u),
            ),
        ]),
      ),
    );
    if (picked == null || !mounted) return;
    guarded(context, () => store.addManualAttendance(e, picked), success: '${picked.name} added');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final e = store.eventById(widget.eventId);
    if (e == null) return const Scaffold(body: Center(child: Text('Event removed')));
    final u = store.currentUser!;
    final canVerify = Perm.verifyAttendance(u, e);
    final all = store.recordsForEvent(e.id);
    final pending = all.where((r) => r.status == AttendanceStatus.pending).toList();
    final list = all.where((r) => switch (_filter) {
          'Pending' => r.status == AttendanceStatus.pending,
          'Inside' => r.isOpen && !e.isMeeting,
          'Flagged' => r.flags.isNotEmpty,
          'Verified' => r.status == AttendanceStatus.verified,
          _ => true,
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendees'),
        actions: [
          IconButton(
            tooltip: 'Copy as CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: all.isEmpty ? null : () => _exportCsv(store, e, all),
          ),
          if (canVerify)
            IconButton(
              tooltip: 'Add manually',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => _addManual(store, e),
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(e.title, style: AppText.title),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text('${Fmt.range(e.startAt, e.endAt)} · ${e.venue}', style: AppText.small),
        ),
        Padding(
          padding: AppSpace.page,
          child: Row(children: [
            Expanded(child: StatTile(label: 'Total', value: '${all.length}')),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile(
                    label: 'Pending',
                    value: '${pending.length}',
                    tone: pending.isEmpty ? Tone.neutral : Tone.warning)),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile(
                    label: 'Flagged',
                    value: '${all.where((r) => r.flags.isNotEmpty).length}',
                    tone: Tone.danger)),
          ]),
        ),
        if (canVerify && pending.length > 1) ...[
          const SizedBox(height: 12),
          Padding(
            padding: AppSpace.page,
            child: OutlinedButton.icon(
              onPressed: () async {
                final clean = pending.where((r) => r.flags.isEmpty).toList();
                final ok = await confirm(context,
                    title: 'Verify ${clean.length} unflagged?',
                    message: 'Flagged records are left for you to check one by one.',
                    confirmLabel: 'Verify');
                if (!ok || !context.mounted) return;
                guarded(context, () {
                  for (final r in clean) {
                    store.review(r, true);
                  }
                }, success: '${clean.length} verified');
              },
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text('Verify all unflagged'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilterChips<String>(
          values: e.isMeeting
              ? const ['All', 'Pending', 'Verified', 'Flagged']
              : const ['All', 'Inside', 'Flagged', 'Verified', 'Pending'],
          selected: _filter,
          label: (v) => v,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.people_outline, title: 'No one here', message: 'Nothing matches this filter.'),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(children: [
              RecordCard(
                record: r,
                showUser: true,
                onTap: () => push(context, SlipScreen(recordId: r.id)),
              ),
              if (canVerify && r.status == AttendanceStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44), foregroundColor: AppColors.danger),
                        onPressed: () => _reject(store, r),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Not present'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44), backgroundColor: AppColors.success),
                        onPressed: () =>
                            guarded(context, () => store.review(r, true), success: 'Verified'),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Present'),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }
}

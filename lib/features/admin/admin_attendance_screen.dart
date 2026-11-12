import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../attendance/my_attendance_screen.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final bool flaggedOnly;
  const AdminAttendanceScreen({super.key, this.flaggedOnly = false});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  late String _f = widget.flaggedOnly ? 'Flagged' : 'All';
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = _q.text.trim().toLowerCase();
    final list = store.attendance
        .where((r) => switch (_f) {
              'Flagged' => r.flags.isNotEmpty,
              'Open' => r.isOpen,
              'Pending' => r.status == AttendanceStatus.pending,
              'Rejected' => r.status == AttendanceStatus.rejected,
              _ => true,
            })
        .where((r) {
          if (q.isEmpty) return true;
          final u = store.userById(r.userId);
          final e = store.eventById(r.eventId);
          return (u?.name.toLowerCase().contains(q) ?? false) ||
              (u?.regNo ?? '').contains(q) ||
              (e?.title.toLowerCase().contains(q) ?? false) ||
              r.slipCode.toLowerCase().contains(q);
        })
        .toList()
      ..sort((a, b) => b.checkInAt.compareTo(a.checkInAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance records')),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: AppSpace.page,
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Student, event or slip code', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        const SizedBox(height: 12),
        FilterChips<String>(
          values: const ['All', 'Flagged', 'Open', 'Pending', 'Rejected'],
          selected: _f,
          label: (v) => v,
          onSelected: (v) => setState(() => _f = v),
        ),
        SectionHeader('${list.length} records'),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: RecordCard(record: r, showUser: true, onTap: () => editRecordSheet(context, r)),
          ),
      ]),
    );
  }
}

/// Admin editor for a single record: fix times, status, flags or delete.
Future<void> editRecordSheet(BuildContext context, AttendanceRecord r) {
  final store = context.read<AppStore>();
  final e = store.eventById(r.eventId);
  final u = store.userById(r.userId);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u?.name ?? 'Unknown student', style: AppText.title),
            Text(e?.title ?? 'Deleted event', style: AppText.small),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.login_rounded, label: 'Check in · ${r.checkInMethod.label}', value: Fmt.full(r.checkInAt)),
            InfoRow(icon: Icons.place_outlined, label: 'In location', value: Fmt.coord(r.checkInLoc.lat, r.checkInLoc.lng)),
            InfoRow(
                icon: Icons.logout_rounded,
                label: 'Check out',
                value: r.checkOutAt == null ? 'None' : Fmt.full(r.checkOutAt!)),
            InfoRow(icon: Icons.confirmation_number_outlined, label: 'Slip', value: r.slipCode),
            if (r.flags.isNotEmpty) InfoRow(icon: Icons.flag_outlined, label: 'Flags', value: r.flags.join(' · ')),
            const FieldLabel('Status'),
            Wrap(spacing: 8, children: [
              for (final s in AttendanceStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: r.status == s,
                  labelStyle: AppText.small.copyWith(
                      color: r.status == s ? Colors.white : AppColors.body, fontWeight: FontWeight.w600),
                  onSelected: (_) {
                    r.status = s;
                    r.reviewedBy = store.currentUser?.id;
                    r.reviewedAt = DateTime.now();
                    guarded(c, () => store.updateRecord(r));
                    set(() {});
                  },
                ),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (r.isOpen && e != null)
                OutlinedButton.icon(
                  onPressed: () {
                    r.checkOutAt = e.endAt;
                    r.checkOutLoc = const GeoStamp();
                    r.note = 'Check-out set by admin';
                    guarded(c, () => store.updateRecord(r), success: 'Check-out set to event end');
                    set(() {});
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Close at event end'),
                ),
              if (r.flags.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    guarded(c, () => store.clearFlags(r), success: 'Flags cleared');
                    set(() {});
                  },
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Clear flags'),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () async {
                  final ok = await confirm(c,
                      title: 'Delete record?',
                      message: 'The student\'s slip stops working. This cannot be undone.',
                      confirmLabel: 'Delete',
                      destructive: true);
                  if (ok && c.mounted) {
                    guarded(c, () => store.deleteRecord(r), success: 'Record deleted');
                    Navigator.pop(c);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
}

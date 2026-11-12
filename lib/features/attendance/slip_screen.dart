import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

/// Attendance slip a student shows (or sends) to a class instructor.
/// The code can be checked by anyone on the "Verify slip" screen.
class SlipScreen extends StatelessWidget {
  final String recordId;
  const SlipScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final r = store.recordById(recordId);
    if (r == null) return const Scaffold(body: Center(child: Text('Record not found')));
    final e = store.eventById(r.eventId);
    final u = store.userById(r.userId);
    final s = store.societyById(e?.societyId);
    final reviewer = store.userById(r.reviewedBy);
    final valid = r.status != AttendanceStatus.rejected &&
        (r.status == AttendanceStatus.verified || (!r.isOpen && r.flags.isEmpty));
    final tone = toneForStatus(r.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance slip')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  SocietyAvatar(s, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s?.name ?? '',
                        style: AppText.small.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(e?.title ?? 'Event removed',
                    style: AppText.title.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(e == null ? '' : '${Fmt.range(e.startAt, e.endAt)} · ${e.venue}',
                    style: AppText.small.copyWith(color: Colors.white60)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(children: [
                Row(children: [
                  UserAvatar(u, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u?.name ?? '', style: AppText.heading),
                      Text('${u?.regNo ?? ''} · ${u?.department ?? ''}', style: AppText.small),
                    ]),
                  ),
                  Pill(r.status.label, tone: tone),
                ]),
                const SizedBox(height: 10),
                const Divider(),
                InfoRow(
                    icon: Icons.login_rounded,
                    label: 'Checked in · ${r.checkInMethod.label}',
                    value: Fmt.full(r.checkInAt)),
                InfoRow(
                    icon: Icons.logout_rounded,
                    label: 'Left',
                    value: r.checkOutAt == null ? 'Still inside' : Fmt.full(r.checkOutAt!)),
                if (r.duration != null)
                  InfoRow(icon: Icons.timelapse_rounded, label: 'Time present', value: Fmt.duration(r.duration!)),
                InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Location stamp',
                    value: Fmt.coord(r.checkInLoc.lat, r.checkInLoc.lng)),
                if (reviewer != null)
                  InfoRow(
                      icon: Icons.verified_outlined,
                      label: r.status == AttendanceStatus.rejected ? 'Rejected by' : 'Verified by',
                      value: '${reviewer.name} · ${Fmt.ago(r.reviewedAt!)}'),
              ]),
            ),
            // perforation
            Row(children: [
              Container(
                  width: 14,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(14)))),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                        (c.maxWidth / 10).floor(),
                        (_) => Container(width: 5, height: 1.5, color: AppColors.lineStrong)),
                  ),
                ),
              ),
              Container(
                  width: 14,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(14)))),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Row(children: [
                QrImageView(
                  data: 'loopair://slip/${r.slipCode}',
                  size: 92,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.navy),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: AppColors.navy),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Slip code', style: AppText.small),
                    const SizedBox(height: 4),
                    Text(r.slipCode, style: AppText.mono.copyWith(fontSize: 17)),
                    const SizedBox(height: 8),
                    Pill(valid ? 'Valid for class attendance' : 'Not yet valid',
                        tone: valid ? Tone.success : Tone.warning,
                        icon: valid ? Icons.check_rounded : Icons.hourglass_empty_rounded),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          valid
              ? 'Give this code to your instructor. They can check it in LoopAir under "Verify an attendance slip" without an account.'
              : r.isOpen && e?.isMeeting != true
                  ? 'Tap Leave when you go to complete this slip.'
                  : r.status == AttendanceStatus.pending
                      ? 'This slip becomes valid once the faculty focal person verifies it.'
                      : 'This record was flagged or rejected, so it cannot be used as a class slip.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
                text: 'LoopAir attendance slip ${r.slipCode}\n${u?.name} (${u?.regNo})\n'
                    '${e?.title}\n${e == null ? '' : Fmt.range(e.startAt, e.endAt)}'));
            toast(context, 'Slip details copied');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy slip details'),
        ),
      ]),
    );
  }
}

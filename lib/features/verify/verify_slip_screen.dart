import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

/// Public page for class instructors: paste a slip code, see if it's real.
/// Solves "the student says they were at a society event during my class".
class VerifySlipScreen extends StatefulWidget {
  const VerifySlipScreen({super.key});
  @override
  State<VerifySlipScreen> createState() => _VerifySlipScreenState();
}

class _VerifySlipScreenState extends State<VerifySlipScreen> {
  final _ctl = TextEditingController();
  AttendanceRecord? _found;
  bool _searched = false;

  void _check() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searched = true;
      _found = context.read<AppStore>().findBySlip(_ctl.text);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final r = _found;
    final e = r == null ? null : store.eventById(r.eventId);
    final u = r == null ? null : store.userById(r.userId);
    final valid = r != null &&
        r.status != AttendanceStatus.rejected &&
        (r.status == AttendanceStatus.verified || (!r.isOpen && r.flags.isEmpty));

    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        const Headline('Verify an\n', 'attendance slip', size: 28),
        const SizedBox(height: 8),
        Text('Students attending society events during class can share a slip code. '
            'Enter it to confirm they were actually there.', style: AppText.body),
        const SizedBox(height: 20),
        TextField(
          controller: _ctl,
          textCapitalization: TextCapitalization.characters,
          style: AppText.mono.copyWith(fontSize: 18, letterSpacing: 2),
          decoration: const InputDecoration(
              hintText: 'LA-XXXX-XXXX', prefixIcon: Icon(Icons.confirmation_number_outlined)),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _check, child: const Text('Check slip')),
        const SizedBox(height: 24),
        if (_searched && r == null)
          AppCard(
            color: AppColors.dangerTint,
            child: Row(children: [
              const Icon(Icons.gpp_bad_outlined, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text('No slip matches this code. It may be mistyped or not genuine.',
                    style: AppText.body.copyWith(color: AppColors.danger)),
              ),
            ]),
          ),
        if (r != null)
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconBadge(valid ? Icons.verified_rounded : Icons.report_gmailerrorred_rounded,
                    bg: valid ? AppColors.successTint : AppColors.warningTint,
                    fg: valid ? AppColors.success : AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(valid ? 'Genuine and valid' : 'Genuine, but not valid for class',
                      style: AppText.heading),
                ),
              ]),
              const SizedBox(height: 12),
              InfoRow(icon: Icons.person_outline, label: 'Student', value: '${u?.name} · ${u?.regNo}'),
              InfoRow(icon: Icons.event_outlined, label: 'Event', value: e?.title ?? 'Removed'),
              if (e != null)
                InfoRow(icon: Icons.schedule_rounded, label: 'Scheduled', value: Fmt.range(e.startAt, e.endAt)),
              InfoRow(
                  icon: Icons.login_rounded,
                  label: 'Present',
                  value: '${Fmt.time(r.checkInAt)} – ${r.checkOutAt == null ? 'no check-out' : Fmt.time(r.checkOutAt!)}'),
              InfoRow(icon: Icons.info_outline_rounded, label: 'Status', value: r.status.label),
              if (r.flags.isNotEmpty)
                InfoRow(icon: Icons.flag_outlined, label: 'Flags', value: r.flags.join(', ')),
            ]),
          ),
      ]),
    );
  }
}

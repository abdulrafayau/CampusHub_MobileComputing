import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/location_service.dart';
import 'slip_screen.dart';

/// Check in to [e]: shows a "stamping" sheet while location is captured,
/// then a result sheet with the stored time and location.
Future<void> performCheckIn(BuildContext context, CampusEvent e, CheckMethod method,
    {String? token}) async {
  final store = context.read<AppStore>();
  final nav = Navigator.of(context);
  _showStamping(context, e.isMeeting ? 'Marking you present' : 'Checking you in');
  final loc = await LocationService.capture();
  final res = store.checkIn(e, method, loc.stamp, locError: loc.error, token: token);
  nav.pop();
  if (!nav.mounted) return;
  await _showResult(nav.context, res, e, arriving: true);
}

Future<void> performCheckOut(BuildContext context, AttendanceRecord r) async {
  final store = context.read<AppStore>();
  final e = store.eventById(r.eventId)!;
  final ok = await confirm(context,
      title: 'Leave ${e.title}?',
      message: 'Your departure time and location will be stamped. You cannot check in again '
          'to this event afterwards.',
      confirmLabel: 'Leave now');
  if (!ok || !context.mounted) return;
  final nav = Navigator.of(context);
  _showStamping(context, 'Stamping your departure');
  final loc = await LocationService.capture();
  final res = store.checkOut(r, loc.stamp, locError: loc.error);
  nav.pop();
  if (!nav.mounted) return;
  await _showResult(nav.context, res, e, arriving: false);
}

void _showStamping(BuildContext context, String title) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.navy)),
            const SizedBox(height: 18),
            Text(title, style: AppText.heading),
            const SizedBox(height: 6),
            Text('Getting the time and your location fix…',
                style: AppText.small, textAlign: TextAlign.center),
          ]),
        ),
      ),
    ),
  );
}

Future<void> _showResult(BuildContext context, ActionResult res, CampusEvent e,
    {required bool arriving}) {
  // Capture now: the widget that started this flow may unmount once the
  // record changes (e.g. the active-session card disappears after Leave).
  final nav = Navigator.of(context);
  final r = res.record;
  final stamp = arriving ? r?.checkInLoc : r?.checkOutLoc;
  final at = arriving ? r?.checkInAt : r?.checkOutAt;
  final flags = r?.flags ?? const <String>[];
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: res.ok ? AppColors.successTint : AppColors.dangerTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(res.ok ? Icons.check_rounded : Icons.close_rounded,
                  color: res.ok ? AppColors.success : AppColors.danger, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
              res.ok
                  ? (arriving ? (e.isMeeting ? 'Marked present' : 'You\'re checked in') : 'You\'ve left')
                  : 'Couldn\'t complete that',
              style: AppText.title),
          const SizedBox(height: 6),
          Text(res.message, style: AppText.body),
          if (res.ok && r != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: AppColors.sunken, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                InfoRow(icon: Icons.schedule_rounded, label: 'Time stamp', value: Fmt.full(at!)),
                InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Location stamp',
                  value: stamp?.known == true
                      ? '${Fmt.coord(stamp!.lat, stamp.lng)}  ±${stamp.accuracy?.round() ?? '?'} m'
                      : 'Not available',
                ),
                InfoRow(icon: Icons.meeting_room_outlined, label: 'Venue', value: e.venue),
              ]),
            ),
            if (flags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.warningTint, borderRadius: BorderRadius.circular(14)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Saved, but flagged for review: ${flags.join(' · ')}. '
                        'If this is wrong, talk to the organiser at the desk.',
                        style: AppText.small.copyWith(color: AppColors.warning)),
                  ),
                ]),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Row(children: [
            if (res.ok && r != null && !arriving)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(c);
                    nav.push(MaterialPageRoute(builder: (_) => SlipScreen(recordId: r.id)));
                  },
                  child: const Text('View slip'),
                ),
              ),
            if (res.ok && r != null && !arriving) const SizedBox(width: 10),
            Expanded(
              child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done')),
            ),
          ]),
        ]),
      ),
    ),
  );
}

/// Bottom sheet to type the 6-digit code shown under the organiser's QR.
Future<void> enterCodeSheet(BuildContext context, CampusEvent e) async {
  final ctl = TextEditingController();
  final code = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(c).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Enter session code', style: AppText.title),
        const SizedBox(height: 6),
        Text('The 6-digit code under the QR on the organiser\'s screen. It changes every 20 seconds.',
            style: AppText.body),
        const SizedBox(height: 16),
        TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppText.mono.copyWith(fontSize: 28, letterSpacing: 10),
          decoration: const InputDecoration(counterText: '', hintText: '000000'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Check in')),
      ]),
    ),
  );
  if (code == null || code.trim().length != 6 || !context.mounted) return;
  await performCheckIn(context, e, CheckMethod.code, token: code.trim());
}

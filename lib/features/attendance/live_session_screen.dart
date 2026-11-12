import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/location_service.dart';
import '../events/attendees_screen.dart';

/// The organiser's / seminar advisor's screen at the gate. Shows a QR that
/// rotates every 20 s plus the matching 6-digit code, and live counts.
class LiveSessionScreen extends StatefulWidget {
  final String eventId;
  const LiveSessionScreen({super.key, required this.eventId});
  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  late Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final e = store.eventById(widget.eventId);
    if (e == null) return const Scaffold(body: Center(child: Text('Event removed')));
    final recs = store.recordsForEvent(e.id);
    final inside = recs.where((r) => r.isOpen).length;
    final left = recs.where((r) => !r.isOpen).length;
    final flagged = recs.where((r) => r.flags.isNotEmpty).length;
    final secs = _now.millisecondsSinceEpoch / 1000;
    final remaining = CheckInToken.period - (secs % CheckInToken.period);
    final open = e.checkInOpen;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text('Live check-in', style: AppText.heading.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Attendees',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => push(context, AttendeesScreen(eventId: e.id)),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        Text(e.title,
            style: AppText.title.copyWith(color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('${e.venue} · ${Fmt.time(e.startAt)} – ${Fmt.time(e.endAt)}',
            style: AppText.small.copyWith(color: Colors.white60), textAlign: TextAlign.center),
        if (e.advisorName != null) ...[
          const SizedBox(height: 2),
          Text('Issued by ${e.advisorName}',
              style: AppText.small.copyWith(color: Colors.white60), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 22),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: open
                ? Container(
                    key: const ValueKey('qr'),
                    padding: const EdgeInsets.all(18),
                    decoration:
                        BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: QrImageView(
                          key: ValueKey(CheckInToken.current(e, _now)),
                          data: CheckInToken.payload(e, _now),
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square, color: AppColors.navy),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square, color: AppColors.navy),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        CheckInToken.current(e, _now).replaceAllMapped(
                            RegExp(r'(\d{3})(\d{3})'), (m) => '${m[1]} ${m[2]}'),
                        style: AppText.mono.copyWith(fontSize: 30, letterSpacing: 6),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: remaining / CheckInToken.period,
                            minHeight: 5,
                            backgroundColor: AppColors.sunken,
                            color: remaining < 5 ? AppColors.live : AppColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('New code in ${remaining.ceil()} s', style: AppText.small),
                    ]),
                  )
                : Container(
                    key: const ValueKey('closed'),
                    width: 260,
                    height: 300,
                    decoration: BoxDecoration(
                        color: AppColors.navySoft, borderRadius: BorderRadius.circular(28)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 40),
                      const SizedBox(height: 12),
                      Text('Check-in is closed',
                          style: AppText.heading.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Open it to show the QR',
                          style: AppText.small.copyWith(color: Colors.white54)),
                    ]),
                  ),
          ),
        ),
        const SizedBox(height: 22),
        Row(children: [
          _Count('Inside now', '$inside', AppColors.sky),
          const SizedBox(width: 10),
          _Count('Left', '$left', AppColors.sage),
          const SizedBox(width: 10),
          _Count('Flagged', '$flagged', AppColors.blush),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: open ? AppColors.navySoft : Colors.white,
            foregroundColor: open ? Colors.white : AppColors.navy,
          ),
          onPressed: () => guarded(context, () => store.setCheckInOpen(e, !open),
              success: open ? 'Check-in closed' : 'Check-in opened'),
          icon: Icon(open ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
          label: Text(open ? 'Close check-in' : 'Open check-in'),
        ),
        const SizedBox(height: 24),
        Text('Latest activity', style: AppText.heading.copyWith(color: Colors.white)),
        const SizedBox(height: 10),
        if (recs.isEmpty)
          Text('No one has checked in yet.', style: AppText.body.copyWith(color: Colors.white54)),
        for (final r in recs.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                UserAvatar(store.userById(r.userId), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(store.userById(r.userId)?.name ?? 'Unknown',
                        style: AppText.bodyStrong.copyWith(color: Colors.white)),
                    Text(
                      r.isOpen
                          ? 'In at ${Fmt.time(r.checkInAt)} · ${r.checkInMethod.label}'
                          : 'Left at ${Fmt.time(r.checkOutAt!)} · ${Fmt.duration(r.duration!)}',
                      style: AppText.small.copyWith(color: Colors.white54),
                    ),
                  ]),
                ),
                if (r.flags.isNotEmpty)
                  const Icon(Icons.flag_rounded, color: Color(0xFFFFB38A), size: 18),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Count extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Count(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppText.number.copyWith(fontSize: 24)),
            Text(label, style: AppText.small.copyWith(color: AppColors.body)),
          ]),
        ),
      );
}

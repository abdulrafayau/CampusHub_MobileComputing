import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/location_service.dart';
import 'check_in_flow.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ctl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handling = false;
  String? _hint;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_handling) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = CheckInToken.parse(raw);
    if (parsed == null) {
      setState(() => _hint = 'That QR isn\'t a LoopAir check-in code');
      return;
    }
    final store = context.read<AppStore>();
    final e = store.eventById(parsed.eventId);
    if (e == null) {
      setState(() => _hint = 'Event not found. It may have been removed.');
      return;
    }
    _handling = true;
    await _ctl.stop();
    if (!mounted) return;
    await performCheckIn(context, e, CheckMethod.qr, token: parsed.token);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickLive() async {
    final store = context.read<AppStore>();
    final now = DateTime.now();
    final live = store.visibleEvents.where((e) => e.isLive(now) && e.checkInOpen).toList();
    final e = await showModalBottomSheet<CampusEvent>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Enter a code instead', style: AppText.title),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Choose the event you are at.', style: AppText.body),
          ),
          if (live.isEmpty)
            const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No open check-ins',
                message: 'None of the live events have opened check-in yet.'),
          for (final ev in live)
            ListRow(
              leading: SocietyAvatar(store.societyById(ev.societyId), size: 40),
              title: ev.title,
              subtitle: ev.venue,
              showChevron: true,
              onTap: () => Navigator.pop(c, ev),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (e == null || !mounted) return;
    if (e.isMeeting) {
      await performCheckIn(context, e, CheckMethod.marked);
    } else {
      await enterCodeSheet(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final box = (size.width * 0.68).clamp(200.0, 320.0);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        MobileScanner(
          controller: _ctl,
          onDetect: _onDetect,
          errorBuilder: (c, err) => Container(
            color: AppColors.navy,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              Text('Camera unavailable',
                  style: AppText.heading.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text('Allow camera access in settings, or enter the session code instead.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: Colors.white60)),
            ]),
          ),
        ),
        // dimmed frame: four flat panels around the cut-out, no gradient
        Positioned.fill(
          child: LayoutBuilder(builder: (_, c) {
            final left = (c.maxWidth - box) / 2;
            final top = (c.maxHeight - box) / 2 - 40;
            final shade = Colors.black.withValues(alpha: 0.55);
            return Stack(children: [
              Positioned(left: 0, right: 0, top: 0, height: top, child: ColoredBox(color: shade)),
              Positioned(left: 0, right: 0, top: top + box, bottom: 0, child: ColoredBox(color: shade)),
              Positioned(left: 0, width: left, top: top, height: box, child: ColoredBox(color: shade)),
              Positioned(right: 0, width: left, top: top, height: box, child: ColoredBox(color: shade)),
              Positioned(
                left: left,
                top: top,
                width: box,
                height: box,
                child: const _Corners(),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: top + box + 24,
                child: Column(children: [
                  Text('Point at the check-in QR',
                      style: AppText.heading.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(_hint ?? 'At the gate or on the organiser\'s screen',
                      style: AppText.body.copyWith(
                          color: _hint != null ? const Color(0xFFFFC9B0) : Colors.white70)),
                ]),
              ),
            ]);
          }),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleIconButton(Icons.close_rounded,
                  bg: Colors.white24, fg: Colors.white, onTap: () => Navigator.pop(context)),
              const Spacer(),
              CircleIconButton(Icons.flash_on_rounded,
                  bg: Colors.white24, fg: Colors.white, onTap: () => _ctl.toggleTorch()),
            ]),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink),
            onPressed: _pickLive,
            icon: const Icon(Icons.dialpad_rounded, size: 20),
            label: const Text('Enter code or mark present'),
          ),
        ),
      ]),
    );
  }
}

class _Corners extends StatelessWidget {
  const _Corners();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CornerPainter());
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 28.0, r = 18.0;
    void corner(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * l)
        ..lineTo(o.dx, o.dy + sy * r)
        ..arcToPoint(Offset(o.dx + sx * r, o.dy),
            radius: const Radius.circular(r), clockwise: sx * sy > 0)
        ..lineTo(o.dx + sx * l, o.dy);
      canvas.drawPath(path, p);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(s.width, 0), -1, 1);
    corner(Offset(0, s.height), 1, -1);
    corner(Offset(s.width, s.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

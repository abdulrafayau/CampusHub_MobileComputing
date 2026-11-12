import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _creators = [
    ('Abdul Rafay', 'AR', AppColors.lavender, AppColors.lavenderInk),
    ('Sinan M Shoaib', 'SS', AppColors.sage, AppColors.sageInk),
    ('Abdul Sattar', 'AS', AppColors.butter, AppColors.butterInk),
  ];

  static const _solves = [
    (Icons.qr_code_scanner_rounded, 'Manual attendance at seminars',
        'Rotating QR at the gate or an in-app button. Arrival and departure are stamped with time and location.'),
    (Icons.verified_user_outlined, 'Proxy marks at society meetings',
        'Students mark present, the society\'s faculty focal person verifies each one.'),
    (Icons.school_outlined, 'Class attendance during events',
        'Every valid record produces a slip code that any instructor can check, no account needed.'),
    (Icons.event_busy_outlined, 'Venue double-bookings',
        'Societies are warned about clashes before publishing an event.'),
    (Icons.manage_search_rounded, 'Anomalies nobody notices',
        'Check-ins far from the venue, missing check-outs and impossible overlaps are flagged for admins.'),
    (Icons.travel_explore_rounded, 'Lost items on campus', 'A shared lost & found board for everyone.'),
    (Icons.add_business_outlined, 'Starting a new society',
        'A proper proposal form, reviewed and published by the administrator.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/building.png', fit: BoxFit.cover, alignment: const Alignment(0.2, 0.4)),
              ColoredBox(color: AppColors.navy.withValues(alpha: 0.55)),
              Positioned(
                left: 20,
                bottom: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Loop', style: AppText.display.copyWith(color: Colors.white, fontSize: 36)),
                    TextSpan(
                        text: 'Air',
                        style: AppText.displayLight.copyWith(color: const Color(0xFF9CC3EE), fontSize: 36)),
                  ])),
                  Text('Version 1.0.0 · Air University, Islamabad',
                      style: AppText.small.copyWith(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Headline('Attendance and societies,\n', 'accounted for.', size: 24),
              const SizedBox(height: 12),
              Text(
                'LoopAir replaces paper sign-in sheets and WhatsApp roll calls with a single, '
                'verifiable record of who attended what. It gives societies, faculty and Student '
                'Affairs one place to run campus life.',
                style: AppText.body.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 26),
              Text('Created by', style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 12),
              Row(children: [
                for (var i = 0; i < _creators.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 132,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _creators[i].$3, borderRadius: BorderRadius.circular(22)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Text(_creators[i].$2,
                              style: AppText.bodyStrong.copyWith(color: _creators[i].$4)),
                        ),
                        const Spacer(),
                        Text(_creators[i].$1, style: AppText.bodyStrong.copyWith(height: 1.2)),
                      ]),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 28),
              Text('What it solves', style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  for (final s in _solves)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        IconBadge(s.$1, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.$2, style: AppText.bodyStrong),
                            const SizedBox(height: 2),
                            Text(s.$3, style: AppText.small),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 24),
              Text('Built with Flutter for Android, iOS and the web.', style: AppText.small),
              const SizedBox(height: 4),
              Text('© ${DateTime.now().year} Abdul Rafay, Sinan M Shoaib, Abdul Sattar.', style: AppText.small),
            ]),
          ),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

/// In-app privacy policy. Google Play also needs this text hosted at a public
/// URL in the Play Console listing.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    ('What we collect',
        'Your name, university email, registration number and programme. When you check in or leave an '
            'event, the time and your device location at that moment. Feedback you choose to give, lost & '
            'found posts, and society memberships.'),
    ('When location is used',
        'Only at the moment you tap Check in, scan a check-in QR, mark yourself present or tap Leave. '
            'LoopAir does not track your location in the background.'),
    ('Why',
        'To prove attendance at university events and society meetings, so it can count toward class '
            'attendance, and to flag records that look wrong (for example a check-in far from the venue).'),
    ('Who can see it',
        'You. The organising society and its faculty focal person, for their own events only. The '
            'administrator, for resolving disputes. Instructors who enter your slip code see that one slip.'),
    ('Security',
        'Passwords are stored as salted PBKDF2-SHA256 hashes. Repeated failed sign-ins lock the account '
            'temporarily. Each role can only perform actions it is authorised for.'),
    ('Your choices',
        'You can deny location permission. Your check-in is still saved but flagged for manual review. '
            'You can delete your account at any time from Profile, which permanently removes your data.'),
    ('Contact', 'Office of Student Affairs, Air University, E-9, Islamabad.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
        const Headline('Privacy\n', 'policy', size: 28),
        const SizedBox(height: 6),
        Text('Last updated November 2026', style: AppText.small),
        const SizedBox(height: 20),
        for (final s in _sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$1, style: AppText.heading),
                const SizedBox(height: 6),
                Text(s.$2, style: AppText.body),
              ]),
            ),
          ),
      ]),
    );
  }
}

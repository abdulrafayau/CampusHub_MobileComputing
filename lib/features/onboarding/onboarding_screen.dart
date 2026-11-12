import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final String light, bold, body;
  final Color bg, ink;
  final IconData icon;
  final List<IconData> chips;
  const _Page(this.light, this.bold, this.body, this.bg, this.ink, this.icon, this.chips);
}

const _pages = [
  _Page(
    'No more paper\n',
    'attendance sheets',
    'Scan the QR at the gate or tap Check in. Your arrival and departure are stamped with the time and your location.',
    AppColors.sky,
    AppColors.skyInk,
    Icons.qr_code_scanner_rounded,
    [Icons.schedule_rounded, Icons.place_rounded, Icons.logout_rounded],
  ),
  _Page(
    'Meetings that\n',
    'count in class',
    'Mark yourself present at society meetings. Your faculty focal person verifies it, and you get a slip any instructor can check.',
    AppColors.sage,
    AppColors.sageInk,
    Icons.verified_rounded,
    [Icons.groups_rounded, Icons.fact_check_rounded, Icons.school_rounded],
  ),
  _Page(
    'Every society,\n',
    'one campus app',
    'Discover societies, join with a tap, follow events, report lost items and propose a new society of your own.',
    AppColors.butter,
    AppColors.butterInk,
    Icons.hub_rounded,
    [Icons.event_rounded, Icons.search_rounded, Icons.add_business_rounded],
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  Future<void> _finish() async {
    await context.read<AppStore>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => const LoginScreen(),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Loop', style: AppText.heading.copyWith(fontSize: 18)),
                TextSpan(
                    text: 'Air',
                    style: AppText.heading.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w300, color: AppColors.brand)),
              ])),
              const Spacer(),
              if (!last) TextButton(onPressed: _finish, child: const Text('Skip')),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => _PageView(_pages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Row(
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _i ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _i ? AppColors.navy : AppColors.lineStrong,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: last ? 160 : 64,
                child: FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _pc.nextPage(
                          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: last
                      ? const Text('Get started')
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _Page p;
  const _PageView(this.p);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(32)),
            child: LayoutBuilder(builder: (_, c) {
              final s = c.maxHeight;
              return Stack(alignment: Alignment.center, children: [
                Positioned(
                  right: -s * 0.12,
                  top: -s * 0.1,
                  child: Container(
                    width: s * 0.55,
                    height: s * 0.55,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35), shape: BoxShape.circle),
                  ),
                ),
                Positioned(
                  left: -s * 0.08,
                  bottom: -s * 0.08,
                  child: Container(
                    width: s * 0.36,
                    height: s * 0.36,
                    decoration: BoxDecoration(
                        color: p.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(s * 0.09)),
                  ),
                ),
                Container(
                  width: s * 0.38,
                  height: s * 0.38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(s * 0.1),
                  ),
                  child: Icon(p.icon, size: s * 0.18, color: p.ink),
                ),
                for (var k = 0; k < p.chips.length; k++)
                  Align(
                    alignment: [
                      const Alignment(-0.72, -0.62),
                      const Alignment(0.74, 0.18),
                      const Alignment(-0.55, 0.7),
                    ][k],
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                      child: Icon(p.chips[k], color: Colors.white, size: 22),
                    ),
                  ),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 28),
        Headline(p.light, p.bold, size: 30),
        const SizedBox(height: 12),
        Text(p.body, style: AppText.body.copyWith(fontSize: 15)),
        const SizedBox(height: 28),
      ]),
    );
  }
}

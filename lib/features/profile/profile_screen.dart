import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../announcements/announcements_screen.dart';
import '../attendance/my_attendance_screen.dart';
import '../auth/login_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/home_shell.dart';
import '../societies/society_request_screen.dart';
import '../verify/verify_slip_screen.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirm(context,
        title: 'Sign out?', message: 'You can sign back in any time.', confirmLabel: 'Sign out');
    if (!ok || !context.mounted) return;
    await context.read<AppStore>().logout();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final store = context.read<AppStore>();
    final pw = TextEditingController();
    String? err;
    final done = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('This permanently removes your profile, attendance history, slips, '
                'lost & found posts and society memberships. It cannot be undone.',
                style: AppText.body),
            const SizedBox(height: 14),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: InputDecoration(hintText: 'Enter your password to confirm', errorText: err),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                final e = await store.deleteOwnAccount(pw.text);
                if (!c.mounted) return;
                if (e != null) {
                  set(() => err = e);
                } else {
                  Navigator.pop(c, true);
                }
              },
              child: const Text('Delete forever'),
            ),
          ],
        ),
      ),
    );
    pw.dispose();
    if (done == true && context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser;
    if (u == null) return const SizedBox();
    final isStudent = u.role == UserRole.student;
    final recs = store.recordsForUser(u.id);
    final hours = store.activityHours(u.id);
    final socs = store.societies.where((s) => s.memberIds.contains(u.id)).length;
    final linked = store.societyById(u.societyId);

    Widget row(IconData i, String t, VoidCallback onTap, {String? sub, Color? bg, Color? fg, Widget? trailing}) =>
        ListRow(
          leading: IconBadge(i, bg: bg ?? AppColors.sunken, fg: fg ?? AppColors.body, size: 38),
          title: t,
          subtitle: sub,
          trailing: trailing,
          showChevron: trailing == null,
          onTap: onTap,
        );

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(0, 12, 0, kNavClearance), children: [
        Padding(
          padding: AppSpace.page,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(28)),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: UserAvatar(u, size: 62),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.name, style: AppText.title.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(u.email, style: AppText.small.copyWith(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.navySoft, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        u.role.label + (linked != null ? ' · ${linked.shortName}' : ''),
                        style: AppText.small.copyWith(color: const Color(0xFF9CC3EE), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
              ]),
              if (isStudent) ...[
                const SizedBox(height: 20),
                Row(children: [
                  _HeroStat('${recs.length}', 'Sessions'),
                  _HeroStat('${hours.inHours}h', 'Activity'),
                  _HeroStat('$socs', 'Societies'),
                ]),
              ],
            ]),
          ),
        ),
        if (isStudent) ...[
          const SectionHeader('Activity'),
          Padding(
            padding: AppSpace.page,
            child: GroupCard(children: [
              row(Icons.insights_rounded, 'My attendance', () => push(context, const MyAttendanceScreen()),
                  sub: 'History, slips and activity time', bg: AppColors.lavender, fg: AppColors.lavenderInk),
              row(Icons.travel_explore_rounded, 'Lost & found', () => push(context, const LostFoundScreen()),
                  bg: AppColors.butter, fg: AppColors.butterInk),
              row(Icons.add_business_outlined, 'Request a new society',
                  () => push(context, const SocietyRequestScreen()), bg: AppColors.blush, fg: AppColors.blushInk),
            ]),
          ),
        ],
        const SectionHeader('General'),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            row(Icons.notifications_none_rounded, 'Notifications', () => push(context, const NotificationsScreen()),
                trailing: store.unreadCount > 0 ? Pill('${store.unreadCount} new', tone: Tone.live) : null),
            row(Icons.campaign_outlined, 'Notice board', () => push(context, const AnnouncementsScreen())),
            if (!isStudent)
              row(Icons.fact_check_outlined, 'Verify an attendance slip',
                  () => push(context, const VerifySlipScreen())),
            if (u.role != UserRole.student && u.role != UserRole.admin)
              row(Icons.travel_explore_rounded, 'Lost & found', () => push(context, const LostFoundScreen())),
          ]),
        ),
        const SectionHeader('Account & privacy'),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            row(Icons.lock_outline_rounded, 'Change password', () => push(context, const ChangePasswordScreen())),
            row(Icons.privacy_tip_outlined, 'Privacy policy', () => push(context, const PrivacyScreen())),
            row(Icons.info_outline_rounded, 'About LoopAir', () => push(context, const AboutScreen())),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            row(Icons.logout_rounded, 'Sign out', () => _signOut(context)),
            if (u.role != UserRole.admin)
              row(Icons.delete_outline_rounded, 'Delete account', () => _deleteAccount(context),
                  bg: AppColors.dangerTint, fg: AppColors.danger),
          ]),
        ),
        const SizedBox(height: 20),
        Center(child: Text('LoopAir 1.0.0 · Air University', style: AppText.small)),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String v, l;
  const _HeroStat(this.v, this.l);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(v, style: AppText.number.copyWith(color: Colors.white, fontSize: 22)),
          Text(l, style: AppText.small.copyWith(color: Colors.white54)),
        ]),
      );
}

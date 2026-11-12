import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../announcements/announcements_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../shell/home_shell.dart';
import 'admin_anomalies_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_events_screen.dart';
import 'admin_societies_screen.dart';
import 'admin_users_screen.dart';
import 'audit_log_screen.dart';

class AdminManageScreen extends StatelessWidget {
  const AdminManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final tiles = [
      ('Users', '${store.users.length} accounts', Icons.people_alt_outlined, AppColors.sky, AppColors.skyInk,
          const AdminUsersScreen()),
      ('Societies', '${store.societies.length} total', Icons.hub_outlined, AppColors.lavender,
          AppColors.lavenderInk, const AdminSocietiesScreen()),
      ('Events', '${store.events.length} total', Icons.event_outlined, AppColors.butter, AppColors.butterInk,
          const AdminEventsScreen()),
      ('Attendance', '${store.attendance.length} records', Icons.fact_check_outlined, AppColors.sage,
          AppColors.sageInk, const AdminAttendanceScreen()),
      ('Anomalies', '${store.anomalies.length} open', Icons.report_gmailerrorred_rounded, AppColors.blush,
          AppColors.blushInk, const AdminAnomaliesScreen()),
      ('Lost & found', '${store.lostItems.length} posts', Icons.travel_explore_rounded, AppColors.sky,
          AppColors.skyInk, const LostFoundScreen()),
      ('Notices', '${store.announcements.length} posted', Icons.campaign_outlined, AppColors.butter,
          AppColors.butterInk, const AnnouncementsScreen()),
      ('Audit log', '${store.audit.length} entries', Icons.history_rounded, AppColors.lavender,
          AppColors.lavenderInk, const AuditLogScreen()),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        const SizedBox(height: 12),
        const PageHeader(eyebrow: 'Developer console', light: 'Manage\n', bold: 'everything'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Text('Create, edit and delete any record to fix anomalies. Every action is written to the audit log.',
              style: AppText.body),
        ),
        Padding(
          padding: AppSpace.page,
          child: GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final t in tiles)
                PastelTile(
                  title: t.$1,
                  caption: t.$2,
                  icon: t.$3,
                  color: t.$4,
                  ink: t.$5,
                  onTap: () => push(context, t.$6),
                ),
            ],
          ),
        ),
        const SectionHeader('Maintenance'),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            ListRow(
              leading: const IconBadge(Icons.restart_alt_rounded, bg: AppColors.dangerTint, fg: AppColors.danger, size: 38),
              title: 'Reset to demo data',
              subtitle: 'Wipes every change and restores the seed dataset',
              showChevron: true,
              onTap: () async {
                final ok = await confirm(context,
                    title: 'Reset all data?',
                    message: 'All users, events, records and posts are replaced by the demo seed. '
                        'This cannot be undone.',
                    confirmLabel: 'Reset',
                    destructive: true);
                if (ok && context.mounted) {
                  guarded(context, () => store.resetDemoData(), success: 'Data reset');
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

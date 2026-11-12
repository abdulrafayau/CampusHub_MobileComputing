import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import 'admin_attendance_screen.dart';
import 'admin_societies_screen.dart';

class AdminAnomaliesScreen extends StatelessWidget {
  const AdminAnomaliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.anomalies;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const PageHeader(light: 'Integrity\n', bold: 'anomalies'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
              'Detected automatically: check-ins outside the venue radius, missing location or check-out, '
              'students present at two events at once, and records left unverified.',
              style: AppText.body),
        ),
        if (list.isEmpty)
          const EmptyState(icon: Icons.verified_rounded, title: 'All clean', message: 'No anomalies right now.'),
        for (final a in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: AppCard(
              onTap: () => a.record != null
                  ? editRecordSheet(context, a.record!)
                  : push(context, const AdminSocietiesScreen()),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                IconBadge(
                  a.severity == 'high'
                      ? Icons.priority_high_rounded
                      : a.severity == 'medium'
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                  bg: a.severity == 'high'
                      ? AppColors.dangerTint
                      : a.severity == 'medium'
                          ? AppColors.warningTint
                          : AppColors.infoTint,
                  fg: a.severity == 'high'
                      ? AppColors.danger
                      : a.severity == 'medium'
                          ? AppColors.warning
                          : AppColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: AppText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(a.detail, style: AppText.small),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
              ]),
            ),
          ),
      ]),
    );
  }
}

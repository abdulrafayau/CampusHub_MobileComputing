import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, Color) _style(NoticeKind k) => switch (k) {
        NoticeKind.attendance => (Icons.fact_check_outlined, AppColors.sage, AppColors.sageInk),
        NoticeKind.membership => (Icons.group_add_outlined, AppColors.sky, AppColors.skyInk),
        NoticeKind.society => (Icons.account_balance_outlined, AppColors.lavender, AppColors.lavenderInk),
        NoticeKind.event => (Icons.event_outlined, AppColors.butter, AppColors.butterInk),
        NoticeKind.system => (Icons.info_outline_rounded, AppColors.blush, AppColors.blushInk),
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.myNotifications();
    return Scaffold(
      appBar: AppBar(actions: [
        if (store.unreadCount > 0)
          TextButton(onPressed: store.markAllRead, child: const Text('Mark all read')),
      ]),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const PageHeader(light: 'Your\n', bold: 'notifications'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'You\'re all caught up',
              message: 'Verifications, membership replies and event updates show up here.'),
        for (final n in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: AppCard(
              color: n.read ? AppColors.surface : AppColors.brandTint,
              onTap: () {
                n.read = true;
                store.markAllRead();
              },
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconBadge(_style(n.kind).$1, bg: _style(n.kind).$2, fg: _style(n.kind).$3),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(n.title, style: AppText.bodyStrong)),
                      Text(Fmt.ago(n.createdAt), style: AppText.small.copyWith(fontSize: 11.5)),
                    ]),
                    const SizedBox(height: 3),
                    Text(n.body, style: AppText.small.copyWith(color: AppColors.body)),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

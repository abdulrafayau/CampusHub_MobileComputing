import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const PageHeader(light: 'Audit\n', bold: 'log'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text('Every administrative and moderation action, newest first.', style: AppText.body),
        ),
        Padding(
          padding: AppSpace.page,
          child: GroupCard(children: [
            for (final a in store.audit)
              ListRow(
                leading: UserAvatar(store.userById(a.actorId), size: 34),
                title: a.action,
                subtitle: '${store.userById(a.actorId)?.name ?? a.actorId} · ${Fmt.full(a.at)}',
              ),
          ]),
        ),
      ]),
    );
  }
}

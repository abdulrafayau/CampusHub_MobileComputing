import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _q = TextEditingController();
  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.societyById(store.currentUser!.societyId);
    if (s == null) return const SizedBox();
    final q = _q.text.trim().toLowerCase();
    final members = s.memberIds
        .map(store.userById)
        .whereType<AppUser>()
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || (u.regNo ?? '').contains(q))
        .toList();
    final pending = s.pendingMemberIds.map(store.userById).whereType<AppUser>().toList();

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        const SizedBox(height: 12),
        PageHeader(light: 'Society\n', bold: 'members', eyebrow: s.shortName),
        if (pending.isNotEmpty) ...[
          SectionHeader('Join requests · ${pending.length}'),
          for (final u in pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  UserAvatar(u, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: AppText.bodyStrong),
                      Text('${u.regNo} · ${u.department}', style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Decline',
                    style: IconButton.styleFrom(backgroundColor: AppColors.dangerTint, foregroundColor: AppColors.danger),
                    onPressed: () => guarded(context, () => store.decideMember(s, u.id, false)),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Accept',
                    style: IconButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () =>
                        guarded(context, () => store.decideMember(s, u.id, true), success: '${u.name} added'),
                    icon: const Icon(Icons.check_rounded, size: 20),
                  ),
                ]),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Search by name or reg. no.', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        SectionHeader('${members.length} members'),
        if (members.isEmpty)
          const EmptyState(icon: Icons.group_off_outlined, title: 'No members', message: 'Nobody matches.'),
        if (members.isNotEmpty)
          Padding(
            padding: AppSpace.page,
            child: GroupCard(children: [
              for (final u in members)
                ListRow(
                  leading: UserAvatar(u, size: 38),
                  title: u.name,
                  subtitle: '${u.regNo} · ${store.recordsForUser(u.id).where((r) => store.eventById(r.eventId)?.societyId == s.id).length} sessions attended',
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.subtle),
                    onSelected: (_) async {
                      final ok = await confirm(context,
                          title: 'Remove ${u.name}?',
                          message: 'They can request to join again later.',
                          confirmLabel: 'Remove',
                          destructive: true);
                      if (ok && context.mounted) guarded(context, () => store.removeMember(s, u.id));
                    },
                    itemBuilder: (_) => const [PopupMenuItem(value: 'rm', child: Text('Remove member'))],
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}

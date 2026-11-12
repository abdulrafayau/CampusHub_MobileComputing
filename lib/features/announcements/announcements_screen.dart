import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final list = store.announcementsFor(u);
    final canPost = u.role == UserRole.admin || (u.role == UserRole.society && u.societyId != null);
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: canPost
          ? FloatingActionButton(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: () => push(
                  context, AnnouncementFormScreen(societyId: u.role == UserRole.admin ? null : u.societyId)),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const PageHeader(light: 'Notice\n', bold: 'board'),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No notices',
              message: 'Campus and society notices you follow appear here.'),
        for (final a in list)
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: AnnouncementCard(a, expanded: true)),
      ]),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final Announcement a;
  final bool expanded;
  const AnnouncementCard(this.a, {super.key, this.expanded = false});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.societyById(a.societyId);
    final canEdit = Perm.postAnnouncement(store.currentUser, a.societyId);
    return AppCard(
      color: a.pinned ? AppColors.butter : null,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (s != null) SocietyAvatar(s, size: 26) else const IconBadge(Icons.account_balance_outlined, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(s?.shortName ?? 'Student Affairs',
                style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.body)),
          ),
          if (a.pinned) const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.butterInk),
          const SizedBox(width: 6),
          Text(Fmt.ago(a.createdAt), style: AppText.small.copyWith(fontSize: 11.5)),
          if (canEdit && expanded)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.muted),
              onSelected: (v) async {
                if (v == 'pin') {
                  a.pinned = !a.pinned;
                  guarded(context, () => store.saveAnnouncement(a));
                } else {
                  final ok = await confirm(context,
                      title: 'Delete notice?', message: a.title, confirmLabel: 'Delete', destructive: true);
                  if (ok && context.mounted) guarded(context, () => store.deleteAnnouncement(a));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pin', child: Text(a.pinned ? 'Unpin' : 'Pin to top')),
                const PopupMenuItem(value: 'del', child: Text('Delete')),
              ],
            ),
        ]),
        const SizedBox(height: 10),
        Text(a.title, style: AppText.heading),
        const SizedBox(height: 4),
        Text(a.body,
            style: AppText.body,
            maxLines: expanded ? null : 2,
            overflow: expanded ? null : TextOverflow.ellipsis),
      ]),
    );
  }
}

class AnnouncementFormScreen extends StatefulWidget {
  final String? societyId;
  const AnnouncementFormScreen({super.key, this.societyId});
  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _t = TextEditingController();
  final _b = TextEditingController();
  bool _pin = false;

  @override
  void dispose() {
    _t.dispose();
    _b.dispose();
    super.dispose();
  }

  void _post() {
    if (_t.text.trim().length < 4 || _b.text.trim().length < 10) {
      toast(context, 'Add a title and a few lines of detail', error: true);
      return;
    }
    final store = context.read<AppStore>();
    final ok = guarded(
      context,
      () => store.saveAnnouncement(Announcement(
        id: store.newId('n'),
        societyId: widget.societyId,
        title: _t.text.trim(),
        body: _b.text.trim(),
        authorId: store.currentUser!.id,
        createdAt: DateTime.now(),
        pinned: _pin,
      )),
      success: 'Notice posted',
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New notice')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
        Text(widget.societyId == null ? 'Visible to everyone on campus.' : 'Visible to your members.',
            style: AppText.body),
        const FieldLabel('Title'),
        TextField(controller: _t, decoration: const InputDecoration(hintText: 'Short and specific')),
        const FieldLabel('Details'),
        TextField(controller: _b, maxLines: 6, decoration: const InputDecoration(hintText: 'What, when, where')),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _pin,
          onChanged: (v) => setState(() => _pin = v),
          title: Text('Pin to top', style: AppText.bodyStrong),
          subtitle: Text('Use for deadlines and important rules', style: AppText.small),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _post, child: const Text('Post notice')),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _tab = 'All';
  bool _showResolved = false;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = _q.text.trim().toLowerCase();
    final items = store.lostItems
        .where((i) => _showResolved || i.status == LostStatus.open)
        .where((i) => switch (_tab) {
              'Lost' => i.type == LostType.lost,
              'Found' => i.type == LostType.found,
              'Mine' => i.postedBy == store.currentUser?.id,
              _ => true,
            })
        .where((i) =>
            q.isEmpty ||
            i.title.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q) ||
            i.location.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => push(context, const LostItemFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post item'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        const PageHeader(light: 'Lost something?\n', bold: 'Found something?'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Search items or places', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        const SizedBox(height: 14),
        FilterChips<String>(
          values: const ['All', 'Lost', 'Found', 'Mine'],
          selected: _tab,
          label: (v) => v,
          onSelected: (v) => setState(() => _tab = v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
          child: Row(children: [
            Expanded(child: Text('${items.length} posts', style: AppText.heading.copyWith(fontSize: 17))),
            Text('Show resolved', style: AppText.small),
            Switch(value: _showResolved, onChanged: (v) => setState(() => _showResolved = v)),
          ]),
        ),
        if (items.isEmpty)
          const EmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'Nothing posted',
              message: 'If you lost or found something on campus, post it so others can help.'),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _LostCard(item: i),
          ),
      ]),
    );
  }
}

class _LostCard extends StatelessWidget {
  final LostItem item;
  const _LostCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final i = item;
    final lost = i.type == LostType.lost;
    final resolved = i.status == LostStatus.resolved;
    return AppCard(
      onTap: () => _showDetail(context, i),
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: resolved ? 0.55 : 1,
        child: Row(children: [
          IconBadge(LostItem.iconFor(i.category),
              bg: lost ? AppColors.blush : AppColors.sage,
              fg: lost ? AppColors.blushInk : AppColors.sageInk,
              size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Pill(lost ? 'Lost' : 'Found', tone: lost ? Tone.danger : Tone.success),
                if (resolved) ...[const SizedBox(width: 6), const Pill('Resolved')],
              ]),
              const SizedBox(height: 6),
              Text(i.title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${i.location} · ${Fmt.ago(i.date)}', style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, LostItem i) {
    final store = context.read<AppStore>();
    final poster = store.userById(i.postedBy);
    final canEdit = Perm.editLost(store.currentUser, i);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Pill(i.type == LostType.lost ? 'Lost' : 'Found',
                  tone: i.type == LostType.lost ? Tone.danger : Tone.success),
              const SizedBox(width: 6),
              Pill(i.category, icon: LostItem.iconFor(i.category)),
            ]),
            const SizedBox(height: 12),
            Text(i.title, style: AppText.title),
            const SizedBox(height: 8),
            Text(i.description, style: AppText.body),
            const SizedBox(height: 10),
            InfoRow(icon: Icons.place_outlined, label: 'Where', value: i.location),
            InfoRow(icon: Icons.schedule_rounded, label: 'When', value: Fmt.full(i.date)),
            InfoRow(icon: Icons.person_outline, label: 'Posted by', value: poster?.name ?? 'Unknown'),
            InfoRow(icon: Icons.alternate_email_rounded, label: 'Contact', value: i.contact),
            const SizedBox(height: 16),
            if (canEdit)
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () async {
                      final ok = await confirm(c,
                          title: 'Delete post?', message: i.title, confirmLabel: 'Delete', destructive: true);
                      if (ok && c.mounted) {
                        guarded(c, () => store.deleteLostItem(i));
                        Navigator.pop(c);
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      guarded(c, () => store.setLostStatus(
                          i, i.status == LostStatus.open ? LostStatus.resolved : LostStatus.open));
                      Navigator.pop(c);
                    },
                    child: Text(i.status == LostStatus.open ? 'Mark resolved' : 'Reopen'),
                  ),
                ),
              ])
            else
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: i.contact));
                  Navigator.pop(c);
                  toast(context, 'Contact copied: ${i.contact}');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(i.type == LostType.lost ? 'I found this · copy contact' : 'This is mine · copy contact'),
              ),
          ]),
        ),
      ),
    );
  }
}

class LostItemFormScreen extends StatefulWidget {
  const LostItemFormScreen({super.key});
  @override
  State<LostItemFormScreen> createState() => _LostItemFormScreenState();
}

class _LostItemFormScreenState extends State<LostItemFormScreen> {
  final _form = GlobalKey<FormState>();
  LostType _type = LostType.lost;
  String _cat = LostItem.categories.first;
  String _loc = campusVenues.first.name;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late final _contact = TextEditingController(text: context.read<AppStore>().currentUser?.email);

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final ok = guarded(
        context,
        () => store.saveLostItem(LostItem(
              id: store.newId('l'),
              type: _type,
              title: _title.text.trim(),
              description: _desc.text.trim(),
              category: _cat,
              location: _loc,
              date: DateTime.now(),
              postedBy: store.currentUser!.id,
              contact: _contact.text.trim(),
            )),
        success: 'Posted');
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post an item')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          SegmentedButton<LostType>(
            segments: const [
              ButtonSegment(value: LostType.lost, label: Text('I lost something')),
              ButtonSegment(value: LostType.found, label: Text('I found something')),
            ],
            selected: {_type},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.navy,
              selectedForegroundColor: Colors.white,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.line),
            ),
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const FieldLabel('What is it?'),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(hintText: 'e.g. Black wireless earbuds'),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Required' : null,
          ),
          const FieldLabel('Category'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in LostItem.categories)
              ChoiceChip(
                label: Text(c),
                selected: _cat == c,
                avatar: Icon(LostItem.iconFor(c), size: 16, color: _cat == c ? Colors.white : AppColors.body),
                labelStyle: AppText.small.copyWith(
                    color: _cat == c ? Colors.white : AppColors.body, fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() => _cat = c),
              ),
          ]),
          const FieldLabel('Where?'),
          DropdownButtonFormField<String>(
            initialValue: _loc,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            items: [
              for (final v in campusVenues) DropdownMenuItem(value: v.name, child: Text(v.name)),
              const DropdownMenuItem(value: 'Elsewhere on campus', child: Text('Elsewhere on campus')),
            ],
            onChanged: (v) => setState(() => _loc = v!),
          ),
          const FieldLabel('Details'),
          TextFormField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Colour, brand, distinguishing marks'),
            validator: (v) => (v == null || v.trim().length < 5) ? 'Add a few details' : null,
          ),
          const FieldLabel('How to reach you'),
          TextFormField(
            controller: _contact,
            validator: (v) => (v == null || v.trim().length < 3) ? 'Required' : null,
          ),
          const SizedBox(height: 6),
          Text('Don\'t post phone numbers publicly. Your university email is enough.', style: AppText.small),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Post')),
        ]),
      ),
    );
  }
}

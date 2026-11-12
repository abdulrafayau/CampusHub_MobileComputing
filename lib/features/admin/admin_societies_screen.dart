import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../societies/society_request_screen.dart';

class AdminSocietiesScreen extends StatelessWidget {
  const AdminSocietiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = [...store.societies]..sort((a, b) => a.shortName.compareTo(b.shortName));
    return Scaffold(
      appBar: AppBar(title: const Text('Societies')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => push(context, const SocietyFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New society'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
        for (final s in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => push(context, SocietyFormScreen(existing: s)),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                SocietyAvatar(s, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.shortName, style: AppText.bodyStrong),
                    Text(
                      '${s.memberIds.length} members · focal: ${store.userById(s.focalFacultyId)?.name ?? 'none'}',
                      style: AppText.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                Pill(s.status == SocietyStatus.active ? 'Active' : 'Suspended',
                    tone: s.status == SocietyStatus.active ? Tone.success : Tone.danger),
              ]),
            ),
          ),
      ]),
    );
  }
}

class SocietyFormScreen extends StatefulWidget {
  final Society? existing;
  const SocietyFormScreen({super.key, this.existing});
  @override
  State<SocietyFormScreen> createState() => _SocietyFormScreenState();
}

class _SocietyFormScreenState extends State<SocietyFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _short = TextEditingController(text: widget.existing?.shortName);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _email = TextEditingController(text: widget.existing?.contactEmail);
  late final _year = TextEditingController(text: '${widget.existing?.foundedYear ?? DateTime.now().year}');
  late String _cat = societyCategories.contains(widget.existing?.category)
      ? widget.existing!.category
      : societyCategories.first;
  late String? _focal = widget.existing?.focalFacultyId;
  late String? _account = widget.existing?.accountUserId;
  late int _color = widget.existing?.colorValue ?? _colors.first;

  static const _colors = [0xFF1B6FB5, 0xFF1E8E3E, 0xFF0F6B5C, 0xFF7A2E2E, 0xFF3F3D56, 0xFFB45309, 0xFF4C5B8C, 0xFF9F1239];

  @override
  void dispose() {
    for (final c in [_name, _short, _desc, _email, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final ex = widget.existing;
    final s = Society(
      id: ex?.id ?? store.newId('s'),
      name: _name.text.trim(),
      shortName: _short.text.trim(),
      category: _cat,
      description: _desc.text.trim(),
      logoAsset: ex?.logoAsset,
      colorValue: _color,
      focalFacultyId: _focal,
      accountUserId: _account,
      foundedYear: int.tryParse(_year.text) ?? DateTime.now().year,
      contactEmail: _email.text.trim(),
      status: ex?.status ?? SocietyStatus.active,
      memberIds: ex?.memberIds,
      pendingMemberIds: ex?.pendingMemberIds,
    );
    if (guarded(context, () => store.saveSociety(s), success: ex == null ? 'Society created' : 'Saved')) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = widget.existing;
    final faculty = store.users.where((u) => u.role == UserRole.faculty).toList();
    final accounts = store.users.where((u) => u.role == UserRole.society).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(ex == null ? 'New society' : ex.shortName),
        actions: [
          if (ex != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (v) async {
                if (v == 'status') {
                  guarded(context, () => store.setSocietyStatus(
                      ex, ex.status == SocietyStatus.active ? SocietyStatus.suspended : SocietyStatus.active));
                } else {
                  final ok = await confirm(context,
                      title: 'Delete ${ex.shortName}?',
                      message: 'All its events, attendance records and notices are deleted too.',
                      confirmLabel: 'Delete',
                      destructive: true);
                  if (ok && context.mounted) {
                    if (guarded(context, () => store.deleteSociety(ex), success: 'Society deleted')) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'status',
                    child: Text(ex.status == SocietyStatus.active ? 'Suspend (hide from students)' : 'Reactivate & publish')),
                const PopupMenuItem(value: 'del', child: Text('Delete society')),
              ],
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          const FieldLabel('Full name'),
          TextFormField(controller: _name, validator: (v) => (v ?? '').trim().length < 3 ? 'Required' : null),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Short name'),
                TextFormField(controller: _short, validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Founded'),
                TextFormField(controller: _year, keyboardType: TextInputType.number),
              ]),
            ),
          ]),
          const FieldLabel('Category'),
          DropdownButtonFormField<String>(
            initialValue: _cat,
            borderRadius: BorderRadius.circular(16),
            items: [for (final c in societyCategories) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _cat = v!),
          ),
          const FieldLabel('Brand colour'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in _colors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == c ? AppColors.ink : Colors.transparent, width: 3),
                  ),
                ),
              ),
          ]),
          const FieldLabel('Faculty focal person'),
          DropdownButtonFormField<String?>(
            initialValue: _focal,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final f in faculty) DropdownMenuItem(value: f.id, child: Text(f.name)),
            ],
            onChanged: (v) => setState(() => _focal = v),
          ),
          const FieldLabel('Society account'),
          DropdownButtonFormField<String?>(
            initialValue: _account,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.email)),
            ],
            onChanged: (v) => setState(() => _account = v),
          ),
          const FieldLabel('Contact email'),
          TextFormField(controller: _email, validator: (v) => (v ?? '').contains('@') ? null : 'Required'),
          const FieldLabel('Description'),
          TextFormField(controller: _desc, maxLines: 4, validator: (v) => (v ?? '').trim().length < 10 ? 'Required' : null),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(ex == null ? 'Create society' : 'Save changes')),
        ]),
      ),
    );
  }
}

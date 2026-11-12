import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';
import '../auth/register_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  UserRole? _role;
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
    final list = store.users
        .where((u) => _role == null || u.role == _role)
        .where((u) =>
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.regNo ?? '').contains(q))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => push(context, const UserFormScreen()),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('New user'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        Padding(
          padding: AppSpace.page,
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Search name, email or reg. no.', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        const SizedBox(height: 12),
        FilterChips<UserRole?>(
          values: const [null, ...UserRole.values],
          selected: _role,
          label: (r) => r == null ? 'All (${store.users.length})' : r.label.split(' ').first,
          onSelected: (r) => setState(() => _role = r),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const EmptyState(icon: Icons.person_search_outlined, title: 'No users', message: 'Nothing matches.'),
        if (list.isNotEmpty)
          Padding(
            padding: AppSpace.page,
            child: GroupCard(children: [
              for (final u in list)
                ListRow(
                  leading: Opacity(opacity: u.active ? 1 : 0.4, child: UserAvatar(u, size: 40)),
                  title: u.name,
                  subtitle: '${u.email}\n${u.role.label}${u.societyId != null ? ' · ${store.societyById(u.societyId)?.shortName ?? ''}' : ''}',
                  trailing: u.active ? null : const Pill('Inactive', tone: Tone.danger),
                  showChevron: u.active,
                  onTap: () => push(context, UserFormScreen(existing: u)),
                ),
            ]),
          ),
      ]),
    );
  }
}

class UserFormScreen extends StatefulWidget {
  final AppUser? existing;
  const UserFormScreen({super.key, this.existing});
  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _reg = TextEditingController(text: widget.existing?.regNo);
  late final _dept = TextEditingController(text: widget.existing?.department);
  final _pw = TextEditingController();
  late UserRole _role = widget.existing?.role ?? UserRole.student;
  late String? _soc = widget.existing?.societyId;

  @override
  void initState() {
    super.initState();
    _pw.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _reg, _dept, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final ex = widget.existing;
    if (store.emailTaken(_email.text.trim(), exceptId: ex?.id)) {
      toast(context, 'That email is already in use', error: true);
      return;
    }
    final u = AppUser(
      id: ex?.id ?? store.newId('u'),
      name: _name.text.trim(),
      email: _email.text.trim().toLowerCase(),
      passwordHash: ex?.passwordHash ?? '',
      role: _role,
      regNo: _reg.text.trim().isEmpty ? null : _reg.text.trim(),
      department: _dept.text.trim(),
      societyId: (_role == UserRole.faculty || _role == UserRole.society) ? _soc : null,
      active: ex?.active ?? true,
      createdAt: ex?.createdAt,
    );
    final ok = guarded(context, () {
      store.saveUser(u, newPassword: _pw.text.isEmpty ? null : _pw.text);
      // keep the society's binding in sync
      final s = store.societyById(u.societyId);
      if (s != null) {
        if (_role == UserRole.faculty) s.focalFacultyId = u.id;
        if (_role == UserRole.society) s.accountUserId = u.id;
        store.saveSociety(s);
      }
    }, success: ex == null ? 'User created' : 'User updated');
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = widget.existing;
    final isSelf = ex?.id == store.currentUser?.id;
    final needsSoc = _role == UserRole.faculty || _role == UserRole.society;
    return Scaffold(
      appBar: AppBar(
        title: Text(ex == null ? 'New user' : 'Edit user'),
        actions: [
          if (ex != null && !isSelf)
            IconButton(
              tooltip: 'Delete user',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirm(context,
                    title: 'Delete ${ex.name}?',
                    message: 'Their attendance records, posts and memberships are removed too. This cannot be undone.',
                    confirmLabel: 'Delete',
                    destructive: true);
                if (ok && context.mounted) {
                  if (guarded(context, () => store.deleteUser(ex), success: 'User deleted')) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          const FieldLabel('Role'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in UserRole.values)
              ChoiceChip(
                label: Text(r.label.split(' ').first),
                selected: _role == r,
                labelStyle: AppText.small.copyWith(
                    color: _role == r ? Colors.white : AppColors.body, fontWeight: FontWeight.w600),
                onSelected: isSelf ? null : (_) => setState(() => _role = r),
              ),
          ]),
          const FieldLabel('Full name'),
          TextFormField(controller: _name, validator: (v) => (v ?? '').trim().length < 3 ? 'Required' : null),
          const FieldLabel('Email'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => EmailRules.valid(v ?? '') ? null : 'Enter a valid email',
          ),
          if (_role == UserRole.student) ...[
            const FieldLabel('Registration number'),
            TextFormField(controller: _reg, keyboardType: TextInputType.number),
          ],
          const FieldLabel('Department / programme'),
          TextFormField(controller: _dept),
          if (needsSoc) ...[
            const FieldLabel('Linked society'),
            DropdownButtonFormField<String>(
              initialValue: _soc,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              hint: const Text('Choose a society'),
              items: [
                for (final s in store.societies) DropdownMenuItem(value: s.id, child: Text('${s.shortName} · ${s.name}', overflow: TextOverflow.ellipsis)),
              ],
              validator: (v) => v == null ? 'Required for this role' : null,
              onChanged: (v) => setState(() => _soc = v),
            ),
          ],
          FieldLabel(ex == null ? 'Password' : 'Reset password', hint: ex == null ? null : 'leave blank to keep'),
          TextFormField(
            controller: _pw,
            obscureText: true,
            validator: (v) {
              if (ex != null && (v == null || v.isEmpty)) return null;
              return PasswordPolicy.validate(v);
            },
          ),
          if (_pw.text.isNotEmpty || ex == null) ...[const SizedBox(height: 10), PasswordChecklist(_pw.text)],
          if (ex != null && !isSelf) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: ex.active,
                title: Text('Account active', style: AppText.bodyStrong),
                subtitle: Text('Inactive users cannot sign in', style: AppText.small),
                onChanged: (v) => guarded(context, () => store.setUserActive(ex, v)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(ex == null ? 'Create user' : 'Save changes')),
        ]),
      ),
    );
  }
}

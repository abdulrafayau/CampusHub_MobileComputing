import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../services/security.dart';
import '../auth/register_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _rep = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _new.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _rep.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final err = await context.read<AppStore>().changePassword(_cur.text, _new.text);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    toast(context, 'Password updated');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          const Headline('Change\n', 'password', size: 28),
          const SizedBox(height: 8),
          Text('Passwords are stored as salted PBKDF2 hashes, never as plain text.', style: AppText.body),
          const FieldLabel('Current password'),
          TextFormField(
            controller: _cur,
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const FieldLabel('New password'),
          TextFormField(controller: _new, obscureText: true, validator: PasswordPolicy.validate),
          const SizedBox(height: 10),
          PasswordChecklist(_new.text),
          const FieldLabel('Repeat new password'),
          TextFormField(
            controller: _rep,
            obscureText: true,
            validator: (v) => v != _new.text ? 'Passwords do not match' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppText.small.copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Update password')),
        ]),
      ),
    );
  }
}

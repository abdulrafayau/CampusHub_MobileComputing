import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../services/security.dart';
import '../profile/privacy_screen.dart';
import '../shell/home_shell.dart';

const departments = [
  'BS Computer Science',
  'BS Software Engineering',
  'BS Artificial Intelligence',
  'BS Cyber Security',
  'BS Data Science',
  'BE Electrical Engineering',
  'BE Mechatronics',
  'BE Mechanical Engineering',
  'BBA',
  'BS Accounting & Finance',
  'BS Psychology',
  'BS English',
  'Other',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _reg = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String _dept = departments.first;
  bool _agree = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pw.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _reg, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _busy = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Please accept the privacy policy to continue');
      return;
    }
    setState(() => _busy = true);
    final err = await context.read<AppStore>().register(
          name: _name.text,
          email: _email.text,
          regNo: _reg.text,
          department: _dept,
          password: _pw.text,
        );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _busy = false;
      });
      return;
    }
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const Headline('Create your\n', 'student account', size: 28),
              const SizedBox(height: 8),
              Text('Faculty and society accounts are issued by the administrator.',
                  style: AppText.body),
              const SizedBox(height: 18),
              const FieldLabel('Full name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'As on your student card'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Enter your full name' : null,
              ),
              const FieldLabel('University email'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'regno@students.au.edu.pk'),
                validator: (v) {
                  if (v == null || !EmailRules.valid(v)) return 'Enter a valid email address';
                  if (!EmailRules.isUniversity(v)) return 'Use your @au.edu.pk email';
                  return null;
                },
              ),
              const FieldLabel('Registration number'),
              TextFormField(
                controller: _reg,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 221034'),
                validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                    ? 'Registration number is 6 digits'
                    : null,
              ),
              const FieldLabel('Programme'),
              DropdownButtonFormField<String>(
                initialValue: _dept,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                items: [for (final d in departments) DropdownMenuItem(value: d, child: Text(d))],
                onChanged: (v) => setState(() => _dept = v!),
              ),
              const FieldLabel('Password'),
              TextFormField(
                controller: _pw,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Create a password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: PasswordPolicy.validate,
              ),
              const SizedBox(height: 10),
              PasswordChecklist(_pw.text),
              const FieldLabel('Confirm password'),
              TextFormField(
                controller: _pw2,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Re-enter password'),
                validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _agree = !_agree),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v ?? false),
                    activeColor: AppColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(children: [
                        Text('I agree that LoopAir stores my check-in time and location stamps. ',
                            style: AppText.small),
                        GestureDetector(
                          onTap: () => push(context, const PrivacyScreen()),
                          child: Text('Read the privacy policy',
                              style: AppText.small.copyWith(
                                  color: AppColors.brand, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AppText.small.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Creating account…' : 'Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordChecklist extends StatelessWidget {
  final String value;
  const PasswordChecklist(this.value, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in PasswordPolicy.rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    r.$2(value) ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    key: ValueKey(r.$2(value)),
                    size: 16,
                    color: r.$2(value) ? AppColors.success : AppColors.subtle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(r.$1,
                    style: AppText.small.copyWith(
                        color: r.$2(value) ? AppColors.success : AppColors.muted)),
              ]),
            ),
        ],
      );
}

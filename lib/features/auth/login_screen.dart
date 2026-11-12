import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../profile/about_screen.dart';
import '../shell/home_shell.dart';
import '../verify/verify_slip_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  static const _demo = [
    (UserRole.student, 'Student', 'student@au.edu.pk', 'student123', Icons.school_outlined,
        AppColors.sky, AppColors.skyInk),
    (UserRole.faculty, 'Faculty', 'faculty@au.edu.pk', 'faculty123', Icons.verified_user_outlined,
        AppColors.sage, AppColors.sageInk),
    (UserRole.society, 'Society', 'seerah@au.edu.pk', 'society123', Icons.groups_outlined,
        AppColors.butter, AppColors.butterInk),
    (UserRole.admin, 'Admin', 'dev@loopair.app', 'admin123', Icons.admin_panel_settings_outlined,
        AppColors.lavender, AppColors.lavenderInk),
  ];

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // let the spinner paint before the hash check
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    final err = await context.read<AppStore>().login(_email.text, _pw.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  void _fill(String e, String p) => setState(() {
        _email.text = e;
        _pw.text = p;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SingleChildScrollView(
        child: Column(children: [
          // ---- hero
          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 16, 16, 36),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Image.asset('assets/logos/air_university.jpeg'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => push(context, const AboutScreen()),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('About'),
                ),
              ]),
              const SizedBox(height: 36),
              const Headline('Welcome back to\n', 'LoopAir', color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text('Check in to seminars, get meetings verified and keep every attendance record in one place.',
                  style: AppText.body.copyWith(color: Colors.white60)),
            ]),
          ),
          // ---- sheet
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.62),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Form(
                      key: _form,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              hintText: 'University email',
                              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20)),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email address'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pw,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: AppColors.dangerTint,
                                        borderRadius: BorderRadius.circular(14)),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_error!,
                                              style: AppText.small.copyWith(color: AppColors.danger))),
                                    ]),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.navy))
                              : const Text('Sign in'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('New student?', style: AppText.body),
                      TextButton(
                        onPressed: () => push(context, const RegisterScreen()),
                        child: const Text('Create an account'),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    AppCard(
                      onTap: () => push(context, const VerifySlipScreen()),
                      child: const Row(children: [
                        IconBadge(Icons.fact_check_outlined, bg: AppColors.blush, fg: AppColors.blushInk),
                        SizedBox(width: 14),
                        Expanded(child: _TwoLine('Are you an instructor?', 'Verify a student\'s attendance slip')),
                        ArrowDot(color: AppColors.sunken),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Text('Try a demo account', style: AppText.heading),
                    const SizedBox(height: 4),
                    Text('Tap a role to fill the form.', style: AppText.small),
                    const SizedBox(height: 12),
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.3,
                      children: [
                        for (final d in _demo)
                          Material(
                            color: d.$6,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _fill(d.$3, d.$4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(children: [
                                  Icon(d.$5, color: d.$7, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(d.$2,
                                        style: AppText.bodyStrong.copyWith(color: AppColors.ink)),
                                  ),
                                  Icon(Icons.north_east_rounded, size: 16, color: d.$7),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TwoLine extends StatelessWidget {
  final String a, b;
  const _TwoLine(this.a, this.b);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(a, style: AppText.bodyStrong), Text(b, style: AppText.small)],
      );
}

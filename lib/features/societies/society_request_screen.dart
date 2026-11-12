import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

const societyCategories = [
  'Technology',
  'Literary',
  'Arts & Media',
  'Sports',
  'Business',
  'Community Service',
  'Religious & Character',
  'Science',
  'Cultural',
];

class SocietyRequestScreen extends StatefulWidget {
  const SocietyRequestScreen({super.key});
  @override
  State<SocietyRequestScreen> createState() => _SocietyRequestScreenState();
}

class _SocietyRequestScreenState extends State<SocietyRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _short = TextEditingController();
  final _mission = TextEditingController();
  final _acts = TextEditingController();
  final _pres = TextEditingController();
  final _presReg = TextEditingController();
  final _advisor = TextEditingController();
  final _email = TextEditingController();
  final _members = TextEditingController(text: '15');
  String _cat = societyCategories.first;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppStore>().currentUser!;
    _pres.text = u.name;
    _presReg.text = u.regNo ?? '';
    _email.text = u.email;
  }

  @override
  void dispose() {
    for (final c in [_name, _short, _mission, _acts, _pres, _presReg, _advisor, _email, _members]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final dup = store.societies.any((s) =>
        s.name.toLowerCase() == _name.text.trim().toLowerCase() ||
        s.shortName.toLowerCase() == _short.text.trim().toLowerCase());
    if (dup) {
      toast(context, 'A society with this name already exists', error: true);
      return;
    }
    store.submitRequest(SocietyRequest(
      id: store.newId('r'),
      name: _name.text.trim(),
      shortName: _short.text.trim().toUpperCase(),
      category: _cat,
      mission: _mission.text.trim(),
      activities: _acts.text.trim(),
      presidentName: _pres.text.trim(),
      presidentRegNo: _presReg.text.trim(),
      proposedAdvisor: _advisor.text.trim(),
      contactEmail: _email.text.trim(),
      foundingMembers: int.tryParse(_members.text) ?? 0,
      submittedBy: store.currentUser!.id,
      submittedAt: DateTime.now(),
    ));
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconBadge(Icons.outgoing_mail, bg: AppColors.sage, fg: AppColors.sageInk, size: 56),
            const SizedBox(height: 16),
            Text('Request submitted', style: AppText.title),
            const SizedBox(height: 6),
            Text('Student Affairs will review ${_name.text.trim()}. You\'ll get a notification when '
                'it\'s approved and published.', style: AppText.body),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ]),
        ),
      ),
    );
  }

  String? _req(String? v, [int min = 3]) =>
      (v == null || v.trim().length < min) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final mine = store.requests.where((r) => r.submittedBy == store.currentUser?.id).toList();
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          const Headline('Propose a\n', 'new society', size: 28),
          const SizedBox(height: 8),
          Text('Tell Student Affairs what you want to start. Approved societies get an account, '
              'a faculty focal person and a listing in LoopAir.', style: AppText.body),
          if (mine.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final r in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: AppText.bodyStrong),
                        Text('Submitted ${Fmt.ago(r.submittedAt)}', style: AppText.small),
                      ]),
                    ),
                    Pill(
                      switch (r.status) {
                        RequestStatus.pending => 'In review',
                        RequestStatus.approved => 'Approved',
                        RequestStatus.rejected => 'Not approved',
                      },
                      tone: switch (r.status) {
                        RequestStatus.pending => Tone.warning,
                        RequestStatus.approved => Tone.success,
                        RequestStatus.rejected => Tone.danger,
                      },
                    ),
                  ]),
                ),
              ),
          ],
          const SizedBox(height: 8),
          const FieldLabel('Society name'),
          TextFormField(controller: _name, decoration: const InputDecoration(hintText: 'Robotics & Embedded Systems Society'), validator: _req),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Short name'),
                TextFormField(
                    controller: _short,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'RESS'),
                    validator: (v) => _req(v, 2)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Category'),
                DropdownButtonFormField<String>(
                  initialValue: _cat,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  items: [for (final c in societyCategories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setState(() => _cat = v!),
                ),
              ]),
            ),
          ]),
          const FieldLabel('Mission'),
          TextFormField(
              controller: _mission,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Why should this society exist?'),
              validator: (v) => _req(v, 20)),
          const FieldLabel('Planned activities'),
          TextFormField(
              controller: _acts,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Events, competitions, sessions for the first year'),
              validator: (v) => _req(v, 10)),
          Row(children: [
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('President'),
                TextFormField(controller: _pres, validator: _req),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Reg. no.'),
                TextFormField(controller: _presReg, keyboardType: TextInputType.number, validator: (v) => _req(v, 6)),
              ]),
            ),
          ]),
          const FieldLabel('Proposed faculty advisor'),
          TextFormField(
              controller: _advisor,
              decoration: const InputDecoration(hintText: 'Name and department'),
              validator: _req),
          Row(children: [
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Contact email'),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, validator: _req),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Founders'),
                TextFormField(
                  controller: _members,
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 10 ? 'Min 10' : null,
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('Submit for review')),
        ]),
      ),
    );
  }
}

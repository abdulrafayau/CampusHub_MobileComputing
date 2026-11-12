import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});
  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  RequestStatus _tab = RequestStatus.pending;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.requests.where((r) => r.status == _tab).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        const SizedBox(height: 12),
        const PageHeader(light: 'Society\n', bold: 'requests'),
        const SizedBox(height: 16),
        FilterChips<RequestStatus>(
          values: RequestStatus.values,
          selected: _tab,
          label: (v) =>
              '${v.name[0].toUpperCase()}${v.name.substring(1)} (${store.requests.where((r) => r.status == v).length})',
          onSelected: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.inbox_outlined, title: 'Nothing here', message: 'New proposals from students land here.'),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: AppCard(
              onTap: () => push(context, RequestDetailScreen(requestId: r.id)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Pill(r.category),
                  const Spacer(),
                  Text(Fmt.ago(r.submittedAt), style: AppText.small),
                ]),
                const SizedBox(height: 10),
                Text(r.name, style: AppText.heading),
                const SizedBox(height: 4),
                Text(r.mission, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.subtle),
                  const SizedBox(width: 4),
                  Text(r.presidentName, style: AppText.small),
                  const SizedBox(width: 12),
                  const Icon(Icons.groups_outlined, size: 16, color: AppColors.subtle),
                  const SizedBox(width: 4),
                  Text('${r.foundingMembers} founders', style: AppText.small),
                  const Spacer(),
                  const ArrowDot(color: AppColors.sunken, size: 30),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});
  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _publish = true;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final r = store.requests.where((x) => x.id == widget.requestId).firstOrNull;
    if (r == null) return const Scaffold(body: Center(child: Text('Request removed')));
    final submitter = store.userById(r.submittedBy);
    final pending = r.status == RequestStatus.pending;

    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: 'Delete request',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () async {
            final ok = await confirm(context,
                title: 'Delete request?', message: r.name, confirmLabel: 'Delete', destructive: true);
            if (ok && context.mounted) {
              guarded(context, () => store.deleteRequest(r));
              Navigator.pop(context);
            }
          },
        ),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
        Row(children: [
          Pill(r.category),
          const SizedBox(width: 6),
          Pill(r.shortName, tone: Tone.brand),
        ]),
        const SizedBox(height: 12),
        Text(r.name, style: AppText.display.copyWith(fontSize: 26)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mission', style: AppText.heading),
            const SizedBox(height: 6),
            Text(r.mission, style: AppText.body),
            const SizedBox(height: 14),
            Text('Planned activities', style: AppText.heading),
            const SizedBox(height: 6),
            Text(r.activities, style: AppText.body),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            InfoRow(icon: Icons.person_outline, label: 'President', value: '${r.presidentName} · ${r.presidentRegNo}'),
            InfoRow(icon: Icons.verified_user_outlined, label: 'Proposed advisor', value: r.proposedAdvisor),
            InfoRow(icon: Icons.groups_outlined, label: 'Founding members', value: '${r.foundingMembers}'),
            InfoRow(icon: Icons.mail_outline_rounded, label: 'Contact', value: r.contactEmail),
            InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Submitted',
                value: '${Fmt.full(r.submittedAt)} by ${submitter?.name ?? 'unknown'}'),
            if (r.adminNote != null && r.adminNote!.isNotEmpty)
              InfoRow(icon: Icons.notes_rounded, label: 'Admin note', value: r.adminNote!),
          ]),
        ),
        const SizedBox(height: 20),
        if (pending) ...[
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _publish,
              onChanged: (v) => setState(() => _publish = v),
              title: Text('Publish on approval', style: AppText.bodyStrong),
              subtitle: Text(
                  _publish
                      ? 'Listed immediately for all students'
                      : 'Created as suspended; publish later from Societies',
                  style: AppText.small),
            ),
          ),
          const FieldLabel('Note to the student', hint: 'optional'),
          TextField(controller: _note, maxLines: 2, decoration: const InputDecoration(hintText: 'Reason or next steps')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () {
                  if (guarded(context, () => store.decideRequest(r, false, note: _note.text.trim()),
                      success: 'Request rejected')) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  if (guarded(
                      context, () => store.decideRequest(r, true, note: _note.text.trim(), publish: _publish),
                      success: _publish ? '${r.shortName} approved and published' : '${r.shortName} approved')) {
                    Navigator.pop(context);
                  }
                },
                child: Text(_publish ? 'Approve & publish' : 'Approve'),
              ),
            ),
          ]),
        ] else
          Pill(r.status == RequestStatus.approved ? 'Approved' : 'Rejected',
              tone: r.status == RequestStatus.approved ? Tone.success : Tone.danger),
      ]),
    );
  }
}

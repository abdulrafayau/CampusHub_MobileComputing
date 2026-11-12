import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../shell/home_shell.dart';
import 'society_detail_screen.dart';
import 'society_request_screen.dart';

class SocietiesScreen extends StatefulWidget {
  const SocietiesScreen({super.key});
  @override
  State<SocietiesScreen> createState() => _SocietiesScreenState();
}

class _SocietiesScreenState extends State<SocietiesScreen> {
  String _cat = 'All';
  final _q = TextEditingController();

  static const _palette = [
    (AppColors.lavender, AppColors.lavenderInk),
    (AppColors.butter, AppColors.butterInk),
    (AppColors.sage, AppColors.sageInk),
    (AppColors.blush, AppColors.blushInk),
    (AppColors.sky, AppColors.skyInk),
  ];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final all = store.activeSocieties;
    final cats = ['All', ...{for (final s in all) s.category}];
    final mine = all.where((s) => s.memberIds.contains(u.id)).toList();
    final q = _q.text.trim().toLowerCase();
    final list = all
        .where((s) => _cat == 'All' || s.category == _cat)
        .where((s) =>
            q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            s.shortName.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: kNavClearance), children: [
        const SizedBox(height: 12),
        PageHeader(
          light: 'Find your\n',
          bold: 'people',
          trailing: CircleIconButton(Icons.add_rounded,
              tooltip: 'Request a new society',
              onTap: () => push(context, const SocietyRequestScreen())),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search ${'societies'}',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        if (mine.isNotEmpty && q.isEmpty) ...[
          const SectionHeader('Your societies'),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpace.page,
              itemCount: mine.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final s = mine[i];
                final c = _palette[i % _palette.length];
                return SizedBox(
                  width: 150,
                  child: Material(
                    color: c.$1,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => push(context, SocietyDetailScreen(societyId: s.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SocietyAvatar(s, size: 44),
                          const Spacer(),
                          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Expanded(
                              child: Text(s.shortName,
                                  style: AppText.heading, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            ArrowDot(color: Colors.white.withValues(alpha: 0.7), iconColor: c.$2, size: 28),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilterChips<String>(
          values: cats,
          selected: _cat,
          label: (v) => v,
          onSelected: (v) => setState(() => _cat = v),
        ),
        SectionHeader('${list.length} societies'),
        if (list.isEmpty)
          const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Can\'t find it? Tap + to propose a new society.'),
        for (final s in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: AppCard(
              onTap: () => push(context, SocietyDetailScreen(societyId: s.id)),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                SocietyAvatar(s, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.shortName, style: AppText.heading),
                    const SizedBox(height: 2),
                    Text(s.name, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      Pill(s.category),
                      const SizedBox(width: 6),
                      Text('${s.memberIds.length} members', style: AppText.small.copyWith(fontSize: 11.5)),
                    ]),
                  ]),
                ),
                if (s.memberIds.contains(u.id))
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                else if (s.pendingMemberIds.contains(u.id))
                  const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 20)
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: AppCard(
            color: AppColors.navy,
            onTap: () => push(context, const SocietyRequestScreen()),
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Missing a society?', style: AppText.heading.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Propose one. Student Affairs reviews every request.',
                      style: AppText.small.copyWith(color: Colors.white60)),
                ]),
              ),
              const ArrowDot(),
            ]),
          ),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../events/event_detail_screen.dart';
import '../events/event_form_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});
  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _f = 'All';

  Future<void> _create(AppStore store) async {
    final s = await showModalBottomSheet<Society>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('For which society?', style: AppText.title)),
          for (final s in store.activeSocieties)
            ListRow(leading: SocietyAvatar(s, size: 36), title: s.shortName, subtitle: s.name, onTap: () => Navigator.pop(c, s)),
        ]),
      ),
    );
    if (s != null && mounted) push(context, EventFormScreen(societyId: s.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final now = DateTime.now();
    final list = store.events.where((e) => switch (_f) {
          'Live' => e.isLive(now) && e.status == EventStatus.published,
          'Upcoming' => e.isUpcoming(now) && e.status == EventStatus.published,
          'Past' => e.isPast(now),
          'Cancelled' => e.status == EventStatus.cancelled,
          _ => true,
        }).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => _create(store),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New event'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        FilterChips<String>(
          values: const ['All', 'Live', 'Upcoming', 'Past', 'Cancelled'],
          selected: _f,
          label: (v) => v,
          onSelected: (v) => setState(() => _f = v),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty) const EmptyState(icon: Icons.event_busy_outlined, title: 'No events', message: 'Nothing matches.'),
        for (final e in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: EventTile(
              e,
              onTap: () => push(context, EventDetailScreen(eventId: e.id)),
              trailing: IconButton(
                tooltip: 'Delete permanently',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.subtle),
                onPressed: () async {
                  final ok = await confirm(context,
                      title: 'Delete "${e.title}"?',
                      message: '${store.recordsForEvent(e.id).length} attendance records will be deleted too. '
                          'This cannot be undone.',
                      confirmLabel: 'Delete',
                      destructive: true);
                  if (ok && context.mounted) guarded(context, () => store.deleteEvent(e), success: 'Event deleted');
                },
              ),
            ),
          ),
      ]),
    );
  }
}

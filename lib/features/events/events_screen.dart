import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';
import '../shell/home_shell.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  /// Society accounts see and manage only their own society's events.
  final bool mineOnly;
  const EventsScreen({super.key, this.mineOnly = false});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _day = WeekStrip.dayOf(DateTime.now());
  String _kind = 'All';
  bool _searching = false;
  bool _allDates = false;
  final _q = TextEditingController();

  static const _kinds = ['All', 'Seminar', 'Workshop', 'Meeting', 'Competition', 'Social', 'Sports'];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser!;
    final now = DateTime.now();
    var events = widget.mineOnly
        ? store.events.where((e) => e.societyId == u.societyId).toList()
        : store.visibleEvents;
    events.sort((a, b) => a.startAt.compareTo(b.startAt));
    final marked = events.map((e) => WeekStrip.dayOf(e.startAt)).toSet();
    if (_kind != 'All') events = events.where((e) => e.kind.label == _kind).toList();
    final q = _q.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      events = events.where((e) {
        final s = store.societyById(e.societyId);
        return e.title.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q) ||
            (s?.shortName.toLowerCase().contains(q) ?? false) ||
            (s?.name.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    final showAll = q.isNotEmpty || _allDates;
    final list = showAll ? events : events.where((e) => WeekStrip.dayOf(e.startAt) == _day).toList();
    final canCreate = u.societyId != null && Perm.manageSociety(u, u.societyId!) && u.role == UserRole.society;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: canCreate
          ? Padding(
              padding: const EdgeInsets.only(bottom: kNavClearance - 24),
              child: FloatingActionButton.extended(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                onPressed: () => push(context, EventFormScreen(societyId: u.societyId!)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New event'),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: widget.mineOnly
                      ? const Headline('Your\n', 'events', size: 28)
                      : const Headline('Campus\n', 'calendar', size: 28),
                ),
                CircleIconButton(_searching ? Icons.close_rounded : Icons.search_rounded,
                    tooltip: 'Search', onTap: () {
                  setState(() {
                    _searching = !_searching;
                    if (!_searching) _q.clear();
                  });
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: _searching
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: TextField(
                        controller: _q,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search events, venues, societies',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
          if (!showAll) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: WeekStrip(
                selected: _day,
                marked: marked,
                onSelect: (d) => setState(() => _day = d),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: FilterChips<String>(
                values: _kinds,
                selected: _kind,
                label: (v) => v,
                onSelected: (v) => setState(() => _kind = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(children: [
                Expanded(
                  child: Text(
                    showAll
                        ? (q.isNotEmpty ? '${list.length} results' : 'All dates')
                        : (_day == WeekStrip.dayOf(now) ? 'Today' : Fmt.day(_day)),
                    style: AppText.heading.copyWith(fontSize: 17),
                  ),
                ),
                if (q.isEmpty)
                  TextButton(
                    onPressed: () => setState(() => _allDates = !_allDates),
                    child: Text(_allDates ? 'By day' : 'Show all',
                        style: AppText.small.copyWith(color: AppColors.muted)),
                  ),
              ]),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No events ${showAll ? 'found' : 'on this day'}',
                message: showAll
                    ? 'Try a different search or category.'
                    : 'Pick a day with a blue marker, or tap Show all.',
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, kNavClearance + 40),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => EventTile(list[i],
                  onTap: () => push(context, EventDetailScreen(eventId: list[i].id))),
            ),
          ),
        ]),
      ),
    );
  }
}

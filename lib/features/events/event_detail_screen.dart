import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/security.dart';
import '../attendance/check_in_flow.dart';
import '../attendance/live_session_screen.dart';
import '../attendance/scan_screen.dart';
import '../attendance/slip_screen.dart';
import '../societies/society_detail_screen.dart';
import 'attendees_screen.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final e = store.eventById(eventId);
    if (e == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Event not found',
              message: 'It may have been removed by the organiser.'));
    }
    final u = store.currentUser!;
    final s = store.societyById(e.societyId);
    final now = DateTime.now();
    final live = e.isLive(now);
    final past = e.isPast(now);
    final mine = store.recordFor(e.id, u.id);
    final recs = store.recordsForEvent(e.id);
    final canManage = Perm.manageSociety(u, e.societyId);
    final canVerify = Perm.verifyAttendance(u, e);
    final isStudent = u.role == UserRole.student;
    final registered = e.registeredIds.contains(u.id);
    final rating = store.averageRating(e.id);
    final cancelled = e.status == EventStatus.cancelled;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 0,
          backgroundColor: AppColors.canvas,
          actions: [
            if (canManage && !cancelled)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (v) async {
                  if (v == 'edit') {
                    push(context, EventFormScreen(societyId: e.societyId, existing: e));
                  } else if (v == 'cancel') {
                    final ok = await confirm(context,
                        title: 'Cancel this event?',
                        message: 'Registered students will be notified. Attendance records are kept.',
                        confirmLabel: 'Cancel event',
                        destructive: true);
                    if (ok && context.mounted) {
                      guarded(context, () => store.cancelEvent(e), success: 'Event cancelled');
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit event')),
                  PopupMenuItem(value: 'cancel', child: Text('Cancel event')),
                ],
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (cancelled) const Pill('Cancelled', tone: Tone.danger),
                if (live && !cancelled) const Pill('Live now', tone: Tone.live, dot: true),
                if (past && !cancelled) const Pill('Ended'),
                Pill(e.kind.label, icon: e.kind.icon),
                Pill(e.isMeeting ? 'Faculty verified' : 'QR + location check-in',
                    tone: Tone.brand),
              ]),
              const SizedBox(height: 14),
              Text(e.title, style: AppText.display.copyWith(fontSize: 27)),
              const SizedBox(height: 16),
              AppCard(
                onTap: s == null ? null : () => push(context, SocietyDetailScreen(societyId: s.id)),
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  SocietyAvatar(s, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Organised by', style: AppText.small),
                      Text(s?.name ?? 'Unknown', style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(children: [
                  InfoRow(icon: Icons.calendar_today_outlined, label: 'When', value: Fmt.range(e.startAt, e.endAt)),
                  InfoRow(
                      icon: Icons.place_outlined,
                      label: 'Where',
                      value: '${e.venue}${e.isMeeting ? '' : ' · check-in radius ${e.radiusMeters} m'}'),
                  if (e.advisorName != null)
                    InfoRow(icon: Icons.person_pin_outlined, label: 'Check-in issued by', value: e.advisorName!),
                  InfoRow(
                      icon: Icons.groups_outlined,
                      label: 'Attendance',
                      value: '${recs.length} checked in · ${e.registeredIds.length} registered'
                          '${e.capacity > 0 ? ' · capacity ${e.capacity}' : ''}'),
                  if (rating != null)
                    InfoRow(
                        icon: Icons.star_outline_rounded,
                        label: 'Rating',
                        value: '${rating.toStringAsFixed(1)} / 5 from ${store.feedback.where((f) => f.eventId == e.id).length} students'),
                ]),
              ),
              const SizedBox(height: 20),
              Text('About', style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              Text(e.description, style: AppText.body.copyWith(fontSize: 15)),
              const SizedBox(height: 22),

              // -------- student actions
              if (isStudent && !cancelled) ...[
                if (mine != null) _MyRecordPanel(record: mine, event: e),
                if (mine == null && live && e.checkInOpen) ...[
                  Text(e.isMeeting ? 'Mark attendance' : 'Check in', style: AppText.heading.copyWith(fontSize: 17)),
                  const SizedBox(height: 10),
                  if (e.isMeeting)
                    FilledButton.icon(
                      onPressed: () => performCheckIn(context, e, CheckMethod.marked),
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: const Text('Mark me present'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: () => push(context, const ScanScreen()),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QR at the gate'),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => performCheckIn(context, e, CheckMethod.app),
                          child: const Text('Check in here'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => enterCodeSheet(context, e),
                          child: const Text('Enter code'),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    e.isMeeting
                        ? 'Your faculty focal person will confirm you were in the room.'
                        : 'Your time and location are stamped. Being outside the venue radius flags the record for review.',
                    style: AppText.small,
                  ),
                ],
                if (mine == null && live && !e.checkInOpen)
                  _Notice(Icons.lock_clock_outlined, 'Check-in opens when the organiser starts the session.'),
                if (mine == null && !live && !past)
                  FilledButton.icon(
                    style: registered
                        ? FilledButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.ink)
                        : null,
                    onPressed: () {
                      final err = store.toggleRegistration(e);
                      if (err != null) {
                        toast(context, err, error: true);
                      } else {
                        toast(context, registered ? 'Registration removed' : 'You\'re registered for this event');
                      }
                    },
                    icon: Icon(registered ? Icons.check_rounded : Icons.bookmark_add_outlined),
                    label: Text(registered ? 'Registered · tap to undo' : 'Register interest'),
                  ),
                if (past && mine != null) ...[
                  const SizedBox(height: 16),
                  _FeedbackPanel(event: e),
                ],
              ],

              // -------- organiser / faculty actions
              if ((canManage || canVerify) && !cancelled) ...[
                Text('Organiser tools', style: AppText.heading.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                if (!e.isMeeting && canManage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      onPressed: () => push(context, LiveSessionScreen(eventId: e.id)),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: Text(e.checkInOpen ? 'Show live check-in QR' : 'Open check-in session'),
                    ),
                  ),
                if (e.isMeeting && canManage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      onPressed: () => guarded(context, () => store.setCheckInOpen(e, !e.checkInOpen),
                          success: e.checkInOpen ? 'Marking closed' : 'Students can now mark attendance'),
                      icon: Icon(e.checkInOpen ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                      label: Text(e.checkInOpen ? 'Close attendance marking' : 'Open attendance marking'),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => push(context, AttendeesScreen(eventId: e.id)),
                  icon: const Icon(Icons.people_alt_outlined, size: 20),
                  label: Text(canVerify
                      ? 'Attendees & verification (${recs.where((r) => r.status == AttendanceStatus.pending).length} pending)'
                      : 'Attendees (${recs.length})'),
                ),
              ],
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.sunken, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: AppColors.muted, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body)),
        ]),
      );
}

class _MyRecordPanel extends StatelessWidget {
  final AttendanceRecord record;
  final CampusEvent event;
  const _MyRecordPanel({required this.record, required this.event});
  @override
  Widget build(BuildContext context) {
    final r = record;
    final canLeave = r.isOpen && !event.isMeeting && !event.isPast(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Your attendance', style: AppText.heading),
          const Spacer(),
          Pill(r.status.label, tone: toneForStatus(r.status)),
        ]),
        const SizedBox(height: 10),
        InfoRow(icon: Icons.login_rounded, label: 'In · ${r.checkInMethod.label}', value: Fmt.full(r.checkInAt)),
        if (r.checkOutAt != null)
          InfoRow(icon: Icons.logout_rounded, label: 'Left', value: '${Fmt.full(r.checkOutAt!)} · ${Fmt.duration(r.duration!)}'),
        if (r.flags.isNotEmpty)
          InfoRow(icon: Icons.flag_outlined, label: 'Flagged', value: r.flags.join(' · ')),
        if (r.note != null) InfoRow(icon: Icons.notes_rounded, label: 'Reviewer note', value: r.note!),
        const SizedBox(height: 10),
        Row(children: [
          if (canLeave) ...[
            Expanded(
              child: FilledButton.icon(
                onPressed: () => performCheckOut(context, r),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Leave'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: OutlinedButton(
              onPressed: () => push(context, SlipScreen(recordId: r.id)),
              child: const Text('View slip'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _FeedbackPanel extends StatefulWidget {
  final CampusEvent event;
  const _FeedbackPanel({required this.event});
  @override
  State<_FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<_FeedbackPanel> {
  int _rating = 0;
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = context.read<AppStore>().myFeedback(widget.event.id);
    if (f != null) {
      _rating = f.rating;
      _c.text = f.comment;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How was it?', style: AppText.heading),
        const SizedBox(height: 4),
        Text('Anonymous to other students. Helps societies plan better events.', style: AppText.small),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              onPressed: () => setState(() => _rating = i),
              icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= _rating ? const Color(0xFFE0A100) : AppColors.subtle, size: 30),
            ),
        ]),
        TextField(
          controller: _c,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Anything to add? (optional)'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () {
                  context.read<AppStore>().submitFeedback(widget.event, _rating, _c.text.trim());
                  toast(context, 'Thanks for the feedback');
                },
          child: const Text('Submit feedback'),
        ),
      ]),
    );
  }
}

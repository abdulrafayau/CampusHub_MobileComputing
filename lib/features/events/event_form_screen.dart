import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class EventFormScreen extends StatefulWidget {
  final String societyId;
  final CampusEvent? existing;
  const EventFormScreen({super.key, required this.societyId, this.existing});
  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _cap = TextEditingController(text: '${widget.existing?.capacity ?? 0}');
  late final _advisor = TextEditingController(text: widget.existing?.advisorName);
  late EventKind _kind = widget.existing?.kind ?? EventKind.seminar;
  late AttendanceMode _mode = widget.existing?.mode ?? AttendanceMode.checkInOut;
  late Venue _venue = campusVenues.firstWhere((v) => v.name == widget.existing?.venue,
      orElse: () => campusVenues.first);
  late int _radius = widget.existing?.radiusMeters ?? 150;
  late DateTime _start = widget.existing?.startAt ??
      DateTime.now().add(const Duration(days: 1)).copyWith(hour: 11, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  late DateTime _end = widget.existing?.endAt ?? _start.add(const Duration(hours: 2));

  @override
  void dispose() {
    for (final c in [_title, _desc, _cap, _advisor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    final dur = _end.difference(_start);
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _end = _start.add(dur);
    });
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    setState(() {
      var e = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute);
      if (!e.isAfter(_start)) e = e.add(const Duration(days: 1));
      _end = e;
    });
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final ex = widget.existing;
    final e = CampusEvent(
      id: ex?.id ?? store.newId('e'),
      societyId: widget.societyId,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      kind: _kind,
      mode: _mode,
      venue: _venue.name,
      lat: _venue.lat,
      lng: _venue.lng,
      radiusMeters: _radius,
      startAt: _start,
      endAt: _end,
      createdBy: ex?.createdBy ?? store.currentUser!.id,
      checkInOpen: ex?.checkInOpen ?? false,
      secret: ex?.secret ?? store.newId('k'),
      capacity: int.tryParse(_cap.text) ?? 0,
      status: ex?.status ?? EventStatus.published,
      registeredIds: ex?.registeredIds,
      advisorName: _advisor.text.trim().isEmpty ? null : _advisor.text.trim(),
    );
    if (guarded(context, () => store.saveEvent(e), success: ex == null ? 'Event published' : 'Event updated')) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final clashes = store.clashesFor(_venue.name, _start, _end, ignoreId: widget.existing?.id);
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New event' : 'Edit event')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
          const FieldLabel('Title'),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(hintText: 'e.g. Seerah-un-Nabi Seminar'),
            validator: (v) => (v == null || v.trim().length < 4) ? 'Give the event a clear title' : null,
          ),
          const FieldLabel('Type'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in EventKind.values)
              ChoiceChip(
                label: Text(k.label),
                selected: _kind == k,
                avatar: Icon(k.icon, size: 16, color: _kind == k ? Colors.white : AppColors.body),
                labelStyle: AppText.small.copyWith(
                    color: _kind == k ? Colors.white : AppColors.body, fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() {
                  _kind = k;
                  _mode = k == EventKind.meeting ? AttendanceMode.facultyVerified : AttendanceMode.checkInOut;
                }),
              ),
          ]),
          const FieldLabel('How is attendance taken?'),
          SegmentedButton<AttendanceMode>(
            segments: const [
              ButtonSegment(
                  value: AttendanceMode.checkInOut,
                  icon: Icon(Icons.qr_code_2_rounded, size: 18),
                  label: Text('QR + location')),
              ButtonSegment(
                  value: AttendanceMode.facultyVerified,
                  icon: Icon(Icons.verified_user_outlined, size: 18),
                  label: Text('Faculty verifies')),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.navy,
              selectedForegroundColor: Colors.white,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.line),
              textStyle: AppText.small.copyWith(fontWeight: FontWeight.w600),
            ),
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 6),
          Text(
            _mode == AttendanceMode.checkInOut
                ? 'Students scan a rotating QR or tap Check in, then Leave. Time and location are stamped both ways.'
                : 'Students mark themselves present; the faculty focal person verifies each one.',
            style: AppText.small,
          ),
          const FieldLabel('Venue'),
          DropdownButtonFormField<Venue>(
            initialValue: _venue,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            items: [for (final v in campusVenues) DropdownMenuItem(value: v, child: Text(v.name))],
            onChanged: (v) => setState(() => _venue = v!),
          ),
          if (_mode == AttendanceMode.checkInOut) ...[
            FieldLabel('Check-in radius', hint: '$_radius m'),
            Slider(
              value: _radius.toDouble(),
              min: 50,
              max: 500,
              divisions: 9,
              activeColor: AppColors.navy,
              label: '$_radius m',
              onChanged: (v) => setState(() => _radius = v.round()),
            ),
          ],
          const FieldLabel('When'),
          Row(children: [
            Expanded(
              child: _PickerBox(label: 'Starts', value: Fmt.full(_start), onTap: _pickStart),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerBox(label: 'Ends', value: Fmt.time(_end), onTap: _pickEnd),
            ),
          ]),
          if (clashes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.event_busy_outlined, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Venue clash: ${_venue.name} is booked for '
                    '${clashes.map((c) => '"${c.title}" (${store.societyById(c.societyId)?.shortName}, ${Fmt.time(c.startAt)}–${Fmt.time(c.endAt)})').join(', ')}. '
                    'Pick another time or venue to avoid a double booking.',
                    style: AppText.small.copyWith(color: AppColors.warning),
                  ),
                ),
              ]),
            ),
          ],
          const FieldLabel('Description'),
          TextFormField(
            controller: _desc,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'What will happen, who should attend, what to bring'),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Add a short description' : null,
          ),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Capacity', hint: '0 = open'),
                TextFormField(controller: _cap, keyboardType: TextInputType.number),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Advisor issuing check-in'),
                TextFormField(controller: _advisor, decoration: const InputDecoration(hintText: 'Optional')),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existing == null ? 'Publish event' : 'Save changes'),
          ),
        ]),
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _PickerBox({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        borderColor: AppColors.line,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.small),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyStrong),
        ]),
      );
}

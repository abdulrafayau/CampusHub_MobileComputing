import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../services/security.dart';
import 'format.dart';
import 'theme.dart';

export 'widgets_extra.dart';

// ---------------------------------------------------------------- tones
enum Tone { neutral, brand, success, warning, danger, live, info }

extension ToneX on Tone {
  Color get fg => switch (this) {
        Tone.neutral => AppColors.body,
        Tone.brand => AppColors.brand,
        Tone.success => AppColors.success,
        Tone.warning => AppColors.warning,
        Tone.danger => AppColors.danger,
        Tone.live => AppColors.live,
        Tone.info => AppColors.info,
      };
  Color get bg => switch (this) {
        Tone.neutral => AppColors.sunken,
        Tone.brand => AppColors.brandTint,
        Tone.success => AppColors.successTint,
        Tone.warning => AppColors.warningTint,
        Tone.danger => AppColors.dangerTint,
        Tone.live => AppColors.liveTint,
        Tone.info => AppColors.infoTint,
      };
}

Tone toneForStatus(AttendanceStatus s) => switch (s) {
      AttendanceStatus.recorded => Tone.brand,
      AttendanceStatus.pending => Tone.warning,
      AttendanceStatus.verified => Tone.success,
      AttendanceStatus.rejected => Tone.danger,
    };

// ---------------------------------------------------------------- pill
class Pill extends StatelessWidget {
  final String text;
  final Tone tone;
  final IconData? icon;
  final bool dot;
  const Pill(this.text, {super.key, this.tone = Tone.neutral, this.icon, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          tone == Tone.live
              ? const LiveDot(size: 6)
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[Icon(icon, size: 13, color: tone.fg), const SizedBox(width: 4)],
        Text(text,
            style: AppText.small.copyWith(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: tone.fg, height: 1.3)),
      ]),
    );
  }
}

class LiveDot extends StatefulWidget {
  final double size;
  final Color color;
  const LiveDot({super.key, this.size = 8, this.color = AppColors.live});
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(alignment: Alignment.center, children: [
          Container(
            width: s + s * _c.value,
            height: s + s * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
            ),
          ),
          Container(
              width: s,
              height: s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- cards
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(AppSpace.lg),
      this.onTap,
      this.color,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  const SectionHeader(this.title,
      {super.key,
      this.actionLabel,
      this.onAction,
      this.padding = const EdgeInsets.fromLTRB(20, 26, 12, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(child: Text(title, style: AppText.heading.copyWith(fontSize: 17))),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(actionLabel!, style: AppText.small.copyWith(color: AppColors.muted)),
          ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState(
      {super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppColors.muted, size: 24),
        ),
        const SizedBox(height: 14),
        Text(title, style: AppText.heading, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(message, style: AppText.small.copyWith(fontSize: 13.5), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppText.small),
            const SizedBox(height: 2),
            Text(value, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w500)),
          ]),
        ),
        ?trailing,
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Tone tone;
  final IconData? icon;
  final VoidCallback? onTap;
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      this.caption,
      this.tone = Tone.neutral,
      this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (icon != null) Icon(icon, size: 16, color: tone == Tone.neutral ? AppColors.subtle : tone.fg),
        ]),
        const SizedBox(height: 8),
        Text(value, style: AppText.number.copyWith(
            color: tone == Tone.neutral ? AppColors.ink : tone.fg)),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: AppText.small.copyWith(fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- avatars
class SocietyAvatar extends StatelessWidget {
  final Society? society;
  final double size;
  const SocietyAvatar(this.society, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final s = society;
    final r = BorderRadius.circular(size * 0.24);
    if (s?.logoAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: r,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(s!.logoAsset!, fit: BoxFit.cover),
      );
    }
    final txt = (s?.shortName ?? '?').replaceAll(RegExp(r'[^A-Za-z]'), '');
    final mono = txt.length >= 2 ? txt.substring(0, 2) : txt;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: s?.color ?? AppColors.muted, borderRadius: r),
      child: Text(
        mono.toUpperCase(),
        style: AppText.bodyStrong.copyWith(
            color: Colors.white, fontSize: size * 0.34, letterSpacing: 0.5, height: 1),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  const UserAvatar(this.user, {super.key, this.size = 40});

  static const _palette = [
    Color(0xFF35577D),
    Color(0xFF2F6B4F),
    Color(0xFF7A4B2A),
    Color(0xFF5B4A8B),
    Color(0xFF6B3A5B),
    Color(0xFF3A6670),
  ];

  @override
  Widget build(BuildContext context) {
    final u = user;
    final c = u == null ? AppColors.subtle : _palette[u.id.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Text(u?.initials ?? '?',
          style: AppText.bodyStrong.copyWith(color: c, fontSize: size * 0.36, height: 1)),
    );
  }
}

// ---------------------------------------------------------------- event tile
class DateBlock extends StatelessWidget {
  final DateTime date;
  final bool highlight;
  const DateBlock(this.date, {super.key, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: highlight ? AppColors.navy : AppColors.sunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(Fmt.month(date),
            style: AppText.label.copyWith(
                fontSize: 10, color: highlight ? Colors.white60 : AppColors.muted, letterSpacing: 1)),
        const SizedBox(height: 1),
        Text('${date.day}',
            style: AppText.title.copyWith(
                fontSize: 19, height: 1.1, color: highlight ? Colors.white : AppColors.ink)),
      ]),
    );
  }
}

class EventTile extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback? onTap;
  final Widget? trailing;
  const EventTile(this.event, {super.key, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.societyById(event.societyId);
    final now = DateTime.now();
    final live = event.isLive(now) && event.status == EventStatus.published;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DateBlock(event.startAt, highlight: live),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (live) ...[const Pill('Live', tone: Tone.live, dot: true), const SizedBox(width: 6)],
              if (event.status == EventStatus.cancelled) ...[
                const Pill('Cancelled', tone: Tone.danger),
                const SizedBox(width: 6)
              ],
              Flexible(
                child: Text(
                  '${s?.shortName ?? ''} · ${event.kind.label}',
                  style: AppText.small.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 5),
            Text(event.title, style: AppText.heading.copyWith(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(spacing: 12, runSpacing: 4, children: [
              _Meta(Icons.schedule, '${Fmt.time(event.startAt)} – ${Fmt.time(event.endAt)}'),
              _Meta(Icons.place_outlined, event.venue),
            ]),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.subtle),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: AppText.small, overflow: TextOverflow.ellipsis)),
      ]);
}

// ---------------------------------------------------------------- list rows
class ListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  const ListRow(
      {super.key,
      this.leading,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      this.showChevron = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          ?trailing,
          if (showChevron) const Icon(Icons.chevron_right, color: AppColors.subtle, size: 20),
        ]),
      ),
    );
  }
}

/// A bordered card containing rows separated by hairlines.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  const GroupCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(const Divider(indent: 16, endIndent: 16));
      }
    }
    return AppCard(padding: EdgeInsets.zero, child: Column(children: items));
  }
}

// ---------------------------------------------------------------- helpers
void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: error ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
}

Future<bool> confirm(BuildContext context,
    {required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancel', style: AppText.bodyStrong.copyWith(color: AppColors.body))),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Labelled form field group used across all forms.
class FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const FieldLabel(this.text, {super.key, this.hint});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Row(children: [
          Text(text, style: AppText.bodyStrong.copyWith(fontSize: 13)),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text(hint!, style: AppText.small),
          ],
        ]),
      );
}

class FilterChips<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  const FilterChips(
      {super.key,
      required this.values,
      required this.selected,
      required this.label,
      required this.onSelected,
      this.padding = const EdgeInsets.symmetric(horizontal: 20)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = values[i];
          final sel = v == selected;
          return ChoiceChip(
            label: Text(label(v)),
            selected: sel,
            onSelected: (_) => onSelected(v),
            labelStyle: AppText.small.copyWith(
              color: sel ? Colors.white : AppColors.body,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: sel ? AppColors.ink : AppColors.line),
          );
        },
      ),
    );
  }
}

/// Runs a store mutation and turns a PermissionDenied into a toast.
bool guarded(BuildContext context, VoidCallback action, {String? success}) {
  try {
    action();
    if (success != null) toast(context, success);
    return true;
  } on PermissionDenied catch (e) {
    toast(context, e.message, error: true);
    return false;
  }
}

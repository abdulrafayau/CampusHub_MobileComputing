import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Two-weight editorial headline: light lead-in, bold payoff.
class Headline extends StatelessWidget {
  final String light;
  final String bold;
  final Color color;
  final double size;
  const Headline(this.light, this.bold, {super.key, this.color = AppColors.ink, this.size = 30});
  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: light, style: AppText.displayLight.copyWith(color: color, fontSize: size)),
          TextSpan(text: bold, style: AppText.display.copyWith(color: color, fontSize: size)),
        ]),
      );
}

/// Circle with a north-east arrow: the "open" affordance on tiles.
class ArrowDot extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final double size;
  const ArrowDot(
      {super.key, this.color = Colors.white, this.iconColor = AppColors.ink, this.size = 34});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(Icons.north_east_rounded, size: size * 0.5, color: iconColor),
      );
}

/// Soft pastel tile used for quick actions and category entry points.
class PastelTile extends StatelessWidget {
  final String title;
  final String? caption;
  final IconData icon;
  final Color color;
  final Color ink;
  final VoidCallback? onTap;
  final double height;
  final String? badge;
  const PastelTile({
    super.key,
    required this.title,
    this.caption,
    required this.icon,
    required this.color,
    required this.ink,
    this.onTap,
    this.height = 148,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.md + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Positioned(
              right: -34,
              top: -34,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icon, size: 22, color: ink),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.navy, borderRadius: BorderRadius.circular(100)),
                      child: Text(badge!,
                          style: AppText.small.copyWith(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: AppText.heading
                              .copyWith(fontSize: 15.5, color: AppColors.ink, height: 1.2)),
                      if (caption != null) ...[
                        const SizedBox(height: 3),
                        Text(caption!,
                            style: AppText.small
                                .copyWith(color: ink.withValues(alpha: 0.85), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ]),
                  ),
                  ArrowDot(color: Colors.white.withValues(alpha: 0.75), iconColor: ink, size: 30),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Tinted rounded-square icon used at the start of rows.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const IconBadge(this.icon,
      {super.key, this.bg = AppColors.sunken, this.fg = AppColors.body, this.size = 42});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(icon, size: size * 0.48, color: fg),
      );
}

/// Round icon button on a disc (top bars), with optional count badge.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color bg;
  final Color fg;
  final int? badgeCount;
  const CircleIconButton(this.icon,
      {super.key,
      this.onTap,
      this.tooltip,
      this.bg = AppColors.surface,
      this.fg = AppColors.ink,
      this.badgeCount});
  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 21, color: fg)),
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(clipBehavior: Clip.none, children: [
        btn,
        if ((badgeCount ?? 0) > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.live,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.canvas, width: 2),
              ),
              child: Text(badgeCount! > 9 ? '9+' : '$badgeCount',
                  style: AppText.small.copyWith(
                      color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, height: 1)),
            ),
          ),
      ]),
    );
  }
}

/// Big two-weight title for second-level screens.
class PageHeader extends StatelessWidget {
  final String? eyebrow;
  final String light;
  final String bold;
  final Widget? trailing;
  const PageHeader(
      {super.key, this.eyebrow, required this.light, required this.bold, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (eyebrow != null) ...[
                Text(eyebrow!, style: AppText.small),
                const SizedBox(height: 6),
              ],
              Headline(light, bold, size: 28),
            ]),
          ),
          ?trailing,
        ]),
      );
}

/// Horizontal day strip with a marker under days that have items.
class WeekStrip extends StatelessWidget {
  final DateTime selected;
  final Set<DateTime> marked;
  final ValueChanged<DateTime> onSelect;
  final int days;
  const WeekStrip(
      {super.key,
      required this.selected,
      required this.marked,
      required this.onSelect,
      this.days = 17});

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final today = dayOf(DateTime.now());
    const names = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final d = today.add(Duration(days: i - 7));
          final sel = dayOf(selected) == d;
          final has = marked.contains(d);
          final isToday = d == today;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 48,
              decoration: BoxDecoration(
                color: sel ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(names[d.weekday - 1],
                    style: AppText.label.copyWith(
                        fontSize: 10,
                        color: sel ? Colors.white60 : (isToday ? AppColors.brand : AppColors.subtle))),
                const SizedBox(height: 4),
                Text('${d.day}',
                    style: AppText.heading.copyWith(
                        color: sel ? Colors.white : AppColors.ink, fontSize: 16.5)),
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: has
                        ? (sel ? const Color(0xFF9CC3EE) : AppColors.brand)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// Semi-circular gauge for rates and progress.
class ArcGauge extends StatelessWidget {
  final double value; // 0..1
  final String center;
  final String caption;
  final double size;
  final Color color;
  const ArcGauge(
      {super.key,
      required this.value,
      required this.center,
      required this.caption,
      this.size = 180,
      this.color = AppColors.navy});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size * 0.52,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => CustomPaint(
            painter: _ArcPainter(v, color),
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.24),
              child: Text(center,
                  textAlign: TextAlign.center,
                  style: AppText.number.copyWith(fontSize: size * 0.17)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      SizedBox(
        width: size,
        child: Text(caption, textAlign: TextAlign.center, style: AppText.small, maxLines: 2),
      ),
    ]);
  }
}

class _ArcPainter extends CustomPainter {
  final double v;
  final Color color;
  _ArcPainter(this.v, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final c = Offset(size.width / 2, r + 8);
    final rect = Rect.fromCircle(center: c, radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    const start = math.pi * 0.95, sweep = math.pi * 1.1;
    canvas.drawArc(rect, start, sweep, false, p..color = AppColors.sunken);
    if (v > 0) canvas.drawArc(rect, start, sweep * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.v != v || o.color != color;
}

/// Simple vertical bar chart (flat bars, rounded tops), no chart lib needed.
class BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final int? highlightIndex;
  const BarChart(
      {super.key,
      required this.values,
      required this.labels,
      this.height = 140,
      this.highlightIndex});

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(0, math.max);
    return SizedBox(
      height: height + 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final f = maxV == 0 ? 0.0 : values[i] / maxV;
          final hi = i == (highlightIndex ?? values.length - 1);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(values[i].round().toString(),
                    style: AppText.small.copyWith(
                        fontSize: 11,
                        color: hi ? AppColors.ink : AppColors.subtle,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: f),
                  duration: Duration(milliseconds: 600 + i * 70),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Container(
                    height: math.max(4, height * v),
                    decoration: BoxDecoration(
                      color: hi ? AppColors.navy : AppColors.lavender,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i],
                    style: AppText.label.copyWith(fontSize: 10, color: AppColors.muted),
                    maxLines: 1),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

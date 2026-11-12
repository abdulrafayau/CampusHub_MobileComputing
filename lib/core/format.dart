import 'package:intl/intl.dart';

class Fmt {
  Fmt._();
  static final _time = DateFormat('h:mm a');
  static final _day = DateFormat('EEE, d MMM');
  static final _dayYear = DateFormat('d MMM yyyy');
  static final _full = DateFormat('EEE, d MMM · h:mm a');

  static String time(DateTime t) => _time.format(t);
  static String day(DateTime t) => _day.format(t);
  static String date(DateTime t) => _dayYear.format(t);
  static String full(DateTime t) => _full.format(t);
  static String month(DateTime t) => DateFormat('MMM').format(t).toUpperCase();

  static String range(DateTime a, DateTime b) {
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    return sameDay ? '${day(a)} · ${time(a)} – ${time(b)}' : '${full(a)} – ${full(b)}';
  }

  static String duration(Duration d) {
    if (d.inMinutes < 1) return '< 1 min';
    if (d.inHours == 0) return '${d.inMinutes} min';
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }

  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.isNegative) {
      final f = -d.inMinutes;
      if (f < 60) return 'in $f min';
      if (f < 60 * 24) return 'in ${(f / 60).round()} h';
      return 'in ${(f / 1440).round()} d';
    }
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return date(t);
  }

  static String coord(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Not available';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

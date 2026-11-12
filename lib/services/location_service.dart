import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../data/models.dart';

class LocationResult {
  final GeoStamp stamp;
  final String? error;
  const LocationResult(this.stamp, [this.error]);
}

class LocationService {
  LocationService._();

  /// Captures the device position for a check-in / check-out stamp.
  /// Never throws: on failure returns an unknown stamp plus a readable reason,
  /// so the record is still saved and flagged for review instead of lost.
  static Future<LocationResult> capture() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(GeoStamp(), 'Location services are turned off');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return const LocationResult(GeoStamp(), 'Location permission denied');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(GeoStamp(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy));
    } catch (e) {
      return const LocationResult(GeoStamp(), 'Could not get a location fix');
    }
  }

  /// Great-circle distance in metres.
  static double distance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}

/// Rotating check-in tokens. The QR on the organiser's screen changes every
/// [period] seconds, so a photo of it forwarded to a friend expires quickly.
class CheckInToken {
  CheckInToken._();
  static const period = 20;
  static const scheme = 'loopair://checkin';

  static int window(DateTime t) => t.millisecondsSinceEpoch ~/ 1000 ~/ period;

  static String code(String eventId, String secret, int window) {
    var h = 0x811c9dc5;
    for (final c in '$secret:$eventId:$window'.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return (h % 1000000).toString().padLeft(6, '0');
  }

  static String current(CampusEvent e, [DateTime? now]) =>
      code(e.id, e.secret, window(now ?? DateTime.now()));

  static String payload(CampusEvent e, [DateTime? now]) =>
      '$scheme?e=${e.id}&t=${current(e, now)}';

  /// Accepts the current window and the previous one (grace for slow scans).
  static bool valid(CampusEvent e, String token, [DateTime? now]) {
    final w = window(now ?? DateTime.now());
    return token == code(e.id, e.secret, w) || token == code(e.id, e.secret, w - 1);
  }

  static ({String eventId, String token})? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !raw.startsWith(scheme)) return null;
    final e = uri.queryParameters['e'];
    final t = uri.queryParameters['t'];
    if (e == null || t == null) return null;
    return (eventId: e, token: t);
  }
}

import 'dart:async';

import 'package:umami_flutter/src/device_id_service.dart';
import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';

/// Lightweight Umami analytics for Flutter.
///
/// ```dart
/// // At startup (returns immediately):
/// UmamiAnalytics.init(
///   websiteId: 'your-website-id',
///   serverUrl: 'https://your-umami.example.com',
///   hostname: 'myapp',
/// );
///
/// // Auto-track screens:
/// MaterialApp(navigatorObservers: [UmamiObserver()]);
///
/// // Manual tracking:
/// UmamiAnalytics.trackScreen('HomeScreen', referrer: 'push://promo');
/// UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro'}, tag: 'summer_sale');
///
/// // Identify session (no PII!):
/// UmamiAnalytics.identify({'plan': 'pro', 'role': 'admin'});
///
/// // GDPR opt-out:
/// UmamiAnalytics.setEnabled(false);
/// ```
class UmamiAnalytics {
  UmamiAnalytics._();

  static Completer<UmamiClient>? _ready;
  static void Function(String)? _log;
  static void Function(Object error)? _onError;
  static bool _enabled = true;

  /// Whether [init] has been called and has not yet failed.
  static bool get isInitialized => _ready != null;

  /// Whether tracking is currently enabled. See [setEnabled].
  static bool get isEnabled => _enabled;

  /// Enables or disables all tracking (e.g. for GDPR consent).
  ///
  /// When `false`, all track/identify calls are silently ignored.
  /// The client stays initialized so tracking resumes instantly on re-enable.
  static void setEnabled(bool value) {
    _enabled = value;
    _log?.call('[UmamiFlutter] Tracking ${value ? 'enabled' : 'disabled'}');
  }

  /// Initializes Umami analytics.
  ///
  /// Returns immediately — device-info collection runs in the background.
  /// Events tracked before init completes are queued and flushed automatically.
  ///
  /// Calling [init] while already initialized is a no-op.
  /// Can be retried after a failure.
  static void init({
    required String websiteId,
    required String serverUrl,
    required String hostname,
    bool enableLogging = false,
    void Function(Object error)? onError,
    String? userAgent,
    bool recordFirstOpen = false,
  }) {
    if (_ready != null && _ready!.isCompleted) {
      if (enableLogging) {
        // ignore: avoid_print
        print('[UmamiFlutter] Already initialized — ignoring duplicate init()');
      }
      return;
    }

    _onError = onError;
    _log = enableLogging
        ? (msg) => print(msg) // ignore: avoid_print
        : null;

    _ready = Completer<UmamiClient>();

    _initAsync(
      websiteId: websiteId,
      serverUrl: serverUrl,
      hostname: hostname,
      userAgent: userAgent,
      recordFirstOpen: recordFirstOpen,
    );
  }

  static Future<void> _initAsync({
    required String websiteId,
    required String serverUrl,
    required String hostname,
    String? userAgent,
    bool recordFirstOpen = false,
  }) async {
    try {
      final start = DateTime.now();
      final deviceInfo = await DeviceInfoService.gather();

      final client = UmamiClient(
        serverUrl: serverUrl,
        websiteId: websiteId,
        hostname: hostname,
        deviceInfo: deviceInfo,
        log: _log,
        onError: _onError,
        userAgent: userAgent,
      );

      _ready!.complete(client);

      if (recordFirstOpen && DeviceIdService.isFirstLaunch) {
        client.trackEvent('first_open');
        _log?.call('[UmamiFlutter] Tracked first_open event');
      }

      _log?.call(
        '[UmamiFlutter] Ready in '
        '${DateTime.now().difference(start).inMilliseconds}ms '
        '| site=$websiteId | $deviceInfo',
      );
    } catch (e) {
      _log?.call('[UmamiFlutter] Init failed: $e');
      _onError?.call(e);
      _ready = null;
    }
  }

  /// Tracks a screen (page) view.
  ///
  /// - [referrer]: Source of navigation — e.g. `'push://promo'`,
  ///   `'/previous-screen'`, or a deep link URL.
  /// - [tag]: Campaign or A/B test label (e.g. `'summer_sale'`).
  /// - [timestamp]: Unix milliseconds — for offline event queuing.
  ///
  /// Subsequent [trackEvent] calls are automatically associated with this screen.
  static void trackScreen(
    String screenName, {
    String? referrer,
    String? tag,
    int? timestamp,
  }) {
    if (!_enabled) return;
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackScreen(
              screenName,
              referrer: referrer,
              tag: tag,
              timestamp: timestamp,
            ))
        .catchError((_) {});
  }

  /// Tracks a custom event with an optional [data] payload.
  ///
  /// - [data]: Key-value map. **Do not include PII** (email, phone, name).
  /// - [tag]: Campaign or A/B test label.
  /// - [timestamp]: Unix milliseconds — for offline event queuing.
  ///
  /// The event is associated with the last screen tracked via [trackScreen].
  static void trackEvent(
    String eventName, {
    Map<String, dynamic>? data,
    String? tag,
    int? timestamp,
  }) {
    if (!_enabled) return;
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackEvent(
              eventName,
              data: data,
              tag: tag,
              timestamp: timestamp,
            ))
        .catchError((_) {});
  }

  /// Associates the current session with non-PII properties.
  ///
  /// Use this to attach plan tier, role, app version, or other anonymous
  /// attributes to a session so you can filter analytics by segment.
  ///
  /// **Security rule:** never send PII — no names, emails, phone numbers,
  /// or any data that could identify a real person. Use opaque IDs or
  /// categorical values only.
  ///
  /// ```dart
  /// UmamiAnalytics.identify({
  ///   'plan': 'pro',
  ///   'role': 'admin',
  ///   'app_version': '2.1.0',
  /// });
  /// ```
  static void identify(Map<String, dynamic> sessionData) {
    if (!_enabled) return;
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.identify(sessionData))
        .catchError((_) {});
  }

  /// Releases the underlying HTTP client.
  ///
  /// After [dispose], call [init] again before tracking resumes.
  static void dispose() {
    _ready?.future.then((c) => c.dispose()).catchError((_) {});
    _ready = null;
    _log = null;
    _onError = null;
  }

  /// Resets all state. Primarily useful for testing.
  static void reset() {
    _ready?.future.then((c) => c.dispose()).catchError((_) {});
    _ready = null;
    _log = null;
    _onError = null;
    _enabled = true;
  }
}

import 'dart:async';

import 'package:umami_flutter/src/device_id_service.dart';
import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';

/// Lightweight Umami analytics for Flutter.
///
/// Provides a simple static API for integrating
/// [Umami](https://umami.is) analytics into any Flutter app.
///
/// **Initialization** is non-blocking — [init] returns immediately while
/// device-info collection happens in the background. Events tracked before
/// init completes are automatically queued and flushed once the client is
/// ready.
///
/// ```dart
/// // At app startup (returns immediately, never blocks):
/// UmamiAnalytics.init(
///   websiteId: 'your-website-id',
///   serverUrl: 'https://your-umami.example.com',
///   hostname: 'myapp',
/// );
///
/// // Track events at any time — even before init finishes:
/// UmamiAnalytics.trackScreen('HomeScreen');
/// UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro'});
///
/// // GDPR / user opt-out:
/// UmamiAnalytics.setEnabled(false); // stops all tracking
/// UmamiAnalytics.setEnabled(true);  // resumes tracking
/// ```
class UmamiAnalytics {
  UmamiAnalytics._();

  static Completer<UmamiClient>? _ready;
  static void Function(String)? _log;
  static void Function(Object error)? _onError;
  static bool _enabled = true;

  /// Whether [init] has been called and has not yet failed.
  static bool get isInitialized => _ready != null;

  /// Whether tracking is currently enabled.
  ///
  /// Use [setEnabled] to toggle. Defaults to `true`.
  static bool get isEnabled => _enabled;

  /// Enables or disables all tracking (e.g. for GDPR consent).
  ///
  /// When set to `false`, [trackScreen] and [trackEvent] are silently ignored.
  /// The analytics client remains initialized so tracking resumes immediately
  /// when re-enabled without another [init] call.
  static void setEnabled(bool value) {
    _enabled = value;
    _log?.call('[UmamiFlutter] Tracking ${value ? 'enabled' : 'disabled'}');
  }

  /// Kicks off device-info collection in the background.
  ///
  /// Returns immediately — never blocks the caller. Events tracked before
  /// init completes are automatically queued and flushed once ready.
  ///
  /// Can be called again after a previous failure to retry initialization.
  /// Calling [init] while a previous init is already successfully completed
  /// is a no-op (a warning is logged if logging is enabled).
  ///
  /// Parameters:
  /// - [websiteId]: The website ID from your Umami dashboard.
  /// - [serverUrl]: The base URL of your Umami server
  ///   (e.g. `https://analytics.example.com`).
  /// - [hostname]: A logical hostname for this app (e.g. `myapp`).
  /// - [enableLogging]: If `true`, prints debug messages to the console.
  ///   Defaults to `false`.
  /// - [onError]: Optional callback invoked when init or event sending fails.
  ///   Useful for monitoring analytics health in production.
  /// - [userAgent]: Optional custom User-Agent string. If omitted, a
  ///   platform-appropriate browser User-Agent is used so Umami can
  ///   recognise the OS.
  /// - [recordFirstOpen]: If `true`, automatically sends a `first_open` event
  ///   when the app is opened for the first time on this device.
  ///   Defaults to `false`.
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
  /// [screenName] is sent as the page URL path and title in Umami.
  /// Subsequent [trackEvent] calls are associated with this screen.
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  /// If [init] has not been called, or tracking is disabled, the call is a no-op.
  static void trackScreen(String screenName) {
    if (!_enabled) return;
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackScreen(screenName))
        .catchError((_) {});
  }

  /// Tracks a custom event with an optional [data] payload.
  ///
  /// [eventName] appears as the event name in the Umami dashboard.
  /// [data] is an arbitrary key-value map attached to the event.
  ///
  /// The event is associated with the last screen tracked via [trackScreen].
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  /// If [init] has not been called, or tracking is disabled, the call is a no-op.
  static void trackEvent(String eventName, {Map<String, dynamic>? data}) {
    if (!_enabled) return;
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackEvent(eventName, data: data))
        .catchError((_) {});
  }

  /// Releases the underlying HTTP client.
  ///
  /// After calling [dispose], [init] must be called again before tracking
  /// can resume. Primarily useful when the analytics lifecycle is tied to
  /// a specific widget or service scope.
  static void dispose() {
    _ready?.future.then((c) => c.dispose()).catchError((_) {});
    _ready = null;
    _log = null;
    _onError = null;
  }

  /// Resets all state, allowing [init] to be called again.
  ///
  /// This is primarily useful for testing.
  static void reset() {
    _ready?.future.then((c) => c.dispose()).catchError((_) {});
    _ready = null;
    _log = null;
    _onError = null;
    _enabled = true;
  }
}

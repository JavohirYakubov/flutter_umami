import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';

import 'package:umami_flutter/src/device_info.dart';

/// Low-level HTTP client that sends events to the Umami `/api/send` endpoint.
///
/// All sends are fire-and-forget so callers are never blocked on network I/O.
///
/// A single [IOClient] is reused across all requests for connection pooling.
class UmamiClient {
  final String _serverUrl;
  final String _websiteId;
  final String _hostname;
  final DeviceInfo _deviceInfo;
  final void Function(String message)? _log;
  final void Function(Object error)? _onError;
  final String _userAgent;
  final IOClient _client;

  // Tracks the last visited screen so events are associated with it.
  String _currentScreen = '/';

  static const Duration _timeout = Duration(seconds: 10);

  UmamiClient({
    required String serverUrl,
    required String websiteId,
    required String hostname,
    required DeviceInfo deviceInfo,
    void Function(String message)? log,
    void Function(Object error)? onError,
    String? userAgent,
  }) : _serverUrl = serverUrl,
       _websiteId = websiteId,
       _hostname = hostname,
       _deviceInfo = deviceInfo,
       _log = log,
       _onError = onError,
       _userAgent = userAgent ?? _defaultUserAgent(),
       _client = IOClient(
         HttpClient()
           ..userAgent = null
           ..connectionTimeout = _timeout,
       );

  /// Track a screen (page) view.
  void trackScreen(String screenName) {
    _currentScreen = '/$screenName';
    _send(url: _currentScreen, title: screenName);
  }

  /// Track a custom event with an optional data payload.
  ///
  /// The event is associated with the last screen tracked via [trackScreen].
  void trackEvent(String eventName, {Map<String, dynamic>? data}) {
    _send(
      url: _currentScreen,
      title: eventName,
      eventName: eventName,
      data: data,
    );
  }

  /// Releases the underlying HTTP client. Call when analytics are no longer needed.
  void dispose() => _client.close();

  // ── Internals ──────────────────────────────────────────────────────────

  void _send({
    required String url,
    required String title,
    String? eventName,
    Map<String, dynamic>? data,
  }) {
    final endpoint = Uri.parse('$_serverUrl/api/send');

    final payload = <String, dynamic>{
      'website': _websiteId,
      'hostname': _hostname,
      'url': url,
      'title': title,
      'screen': _deviceInfo.screenResolution,
      'language': _deviceInfo.locale,
      'id': _deviceInfo.deviceId,
    };

    if (eventName != null) payload['name'] = eventName;
    if (data != null) payload['data'] = data;

    _log?.call('[UmamiFlutter] Sending: $title');

    final body = jsonEncode({'type': 'event', 'payload': payload});

    _client
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
          },
          body: body,
        )
        .timeout(_timeout)
        .then((_) {
          _log?.call('[UmamiFlutter] Sent: $title');
        })
        .catchError((Object e) {
          _log?.call('[UmamiFlutter] Failed: $e');
          _onError?.call(e);
        });
  }

  /// Platform-aware User-Agent so Umami recognises the OS.
  ///
  /// Uses realistic browser UA strings because Umami parses the User-Agent
  /// header to populate OS / browser / device-type fields.
  static String _defaultUserAgent() {
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) '
          'Version/17.0 Mobile/15E148 Safari/604.1';
    } else if (Platform.isMacOS) {
      return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/122.0.0.0 Safari/537.36';
    }
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
  }
}

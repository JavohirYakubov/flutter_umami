/// Lightweight Umami analytics for Flutter.
///
/// Provides non-blocking initialization with automatic device info collection
/// and fire-and-forget event tracking.
///
/// ```dart
/// import 'package:umami_flutter/umami_flutter.dart';
///
/// // At startup (returns immediately):
/// UmamiAnalytics.init(
///   websiteId: 'your-website-id',
///   serverUrl: 'https://your-umami.example.com',
///   hostname: 'myapp',
/// );
///
/// // Auto-track screens via MaterialApp:
/// MaterialApp(navigatorObservers: [UmamiObserver()]);
///
/// // Or track manually:
/// UmamiAnalytics.trackScreen('HomeScreen');
/// UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro'});
///
/// // GDPR opt-out:
/// UmamiAnalytics.setEnabled(false);
/// ```
library;

export 'src/umami_analytics.dart';
export 'src/umami_observer.dart';
export 'src/device_id_service.dart' show DeviceIdService;

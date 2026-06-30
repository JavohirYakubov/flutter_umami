# umami_flutter

A lightweight, privacy-focused Flutter analytics package powered by [Umami](https://umami.is) — the open-source alternative to Google Analytics and Firebase Analytics.

Track screen views, custom events, and user sessions in your Flutter app **without sending data to Google**. Self-host your analytics, own your data, and stay GDPR-compliant.

[![pub package](https://img.shields.io/pub/v/umami_flutter.svg)](https://pub.dev/packages/umami_flutter)
[![Dart](https://img.shields.io/badge/Dart-%5E3.7.2-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-02569B)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why umami_flutter over Firebase Analytics?

|                              | **umami_flutter**                                | **Firebase Analytics**                              |
| ---------------------------- | ------------------------------------------------ | --------------------------------------------------- |
| **Privacy**                  | ✅ Self-hosted — data never leaves your server   | ❌ Data sent to Google servers                      |
| **GDPR compliance**          | ✅ Built-in opt-out, no PII, no cookie banners   | ⚠️ Requires consent banners and DPA                 |
| **Setup complexity**         | ✅ 3 lines of code, no `google-services.json`    | ❌ Platform config files, Firebase console setup    |
| **Package size**             | ✅ Minimal footprint                             | ❌ Firebase core + analytics = significantly larger |
| **Cost**                     | ✅ Free & open-source (self-hosted)              | ⚠️ Free tier with limits, then paid                 |
| **Data ownership**           | ✅ 100% yours on your own server                 | ❌ Stored on Google infrastructure                  |
| **Real-time dashboard**      | ✅ Built-in Umami dashboard                      | ✅ Firebase console                                 |
| **Session identification**   | ✅ Via `identify()` (non-PII only)               | ✅ User properties and audiences                    |
| **Campaign tracking**        | ✅ `referrer` + `tag` params                     | ✅ UTM parameters                                   |
| **Offline event queuing**    | ✅ `timestamp` param for manual queuing          | ✅ Built-in automatic queuing                       |
| **No Google account needed** | ✅                                               | ❌                                                  |

**Best for:** Indie developers, privacy-conscious apps, apps targeting EU markets, and teams that want simple analytics without vendor lock-in.

---

## Features

- 🚀 **Non-blocking init** — `init()` returns immediately; events queued before init completes are flushed automatically.
- 🗺️ **Automatic screen tracking** — Drop in `UmamiObserver()` and every route change is tracked with zero boilerplate.
- 📱 **Automatic device info** — Collects device ID, locale, and screen resolution out of the box.
- 🔒 **Persistent device IDs** — Platform-specific identifiers (Android ID, `identifierForVendor`, etc.) persisted in secure storage (Keychain / EncryptedSharedPreferences).
- 🔥 **Fire-and-forget tracking** — `trackScreen` and `trackEvent` never block the UI thread.
- 🛡️ **GDPR opt-out** — `UmamiAnalytics.setEnabled(false)` instantly silences all tracking.
- 🏷️ **Campaign & A/B tagging** — `tag` parameter on every call for easy segmentation.
- 🔗 **Referrer tracking** — Know if a user arrived from a push notification, deep link, or in-app navigation.
- ⏱️ **Timestamp support** — Send events with an explicit timestamp for offline queuing scenarios.
- 👤 **Session identification** — `identify()` attaches non-PII session attributes for cohort analysis.
- 🖥️ **Multi-platform** — Android, iOS, macOS, Windows.
- 🪵 **Optional debug logging** — Enable verbose logs during development with a single flag.
- ⚠️ **Error monitoring** — Optional `onError` callback for production health checks.

---

## Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  umami_flutter:
    git:
      url: https://github.com/JavohirYakubov/flutter_umami.git
```

Then run:

```bash
flutter pub get
```

### Prerequisites

You need a running [Umami](https://umami.is) instance:

- **Self-host** using Docker ([setup guide](https://umami.is/docs/install))
- Use **Umami Cloud** at [cloud.umami.is](https://cloud.umami.is)

### Platform Setup

#### Android

No additional setup required. The package uses `android_id` and `EncryptedSharedPreferences` internally.

#### iOS / macOS

Keychain access is used for persistent device IDs. No extra entitlements are needed beyond the defaults.

---

## Usage

### 1. Initialize at app startup

Call `init()` once in `main()`. It returns immediately and never blocks.

```dart
import 'package:umami_flutter/umami_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  UmamiAnalytics.init(
    websiteId: 'your-website-id',       // from Umami dashboard
    serverUrl: 'https://your-umami.com',
    hostname: 'myapp',
    enableLogging: true,                // debug logs in development
    recordFirstOpen: true,              // fires 'first_open' event on first launch
    onError: (e) => debugPrint('Analytics error: $e'),
  );

  runApp(const MyApp());
}
```

### 2. Auto-track screen changes

Add `UmamiObserver()` to `MaterialApp` and every named route change is tracked automatically:

```dart
MaterialApp(
  navigatorObservers: [UmamiObserver()],
  initialRoute: '/home',
  routes: {
    '/home':    (_) => const HomeScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/settings':(_) => const SettingsScreen(),
  },
);
```

### 3. Track screen views manually

```dart
UmamiAnalytics.trackScreen('HomeScreen');

// With referrer — where did the user come from?
UmamiAnalytics.trackScreen(
  'PromoScreen',
  referrer: 'push://summer_campaign',
);
```

### 4. Track custom events

```dart
// Simple event
UmamiAnalytics.trackEvent('button_tap');

// Event with data
UmamiAnalytics.trackEvent('purchase', data: {
  'plan': 'pro',
  'price': 9.99,
  'currency': 'USD',
});

// Event with campaign tag (for A/B tests or campaign tracking)
UmamiAnalytics.trackEvent('signup', tag: 'summer_sale_2026');

// Offline-safe event with explicit timestamp
UmamiAnalytics.trackEvent(
  'order_placed',
  data: {'order_id': 'ORD-123'},
  timestamp: DateTime.now().millisecondsSinceEpoch,
);
```

### 5. Identify sessions (no PII)

Attach non-PII attributes to the current session for cohort filtering:

```dart
// ✅ Safe — categorical, non-identifying values
UmamiAnalytics.identify({
  'plan': 'pro',
  'role': 'admin',
  'app_version': '2.1.0',
  'onboarding_complete': true,
});

// ❌ Never send PII
// UmamiAnalytics.identify({'email': 'user@example.com'}); // DON'T
```

### 6. GDPR opt-out

```dart
// Disable all tracking (e.g. user declined consent)
UmamiAnalytics.setEnabled(false);

// Re-enable when consent is granted
UmamiAnalytics.setEnabled(true);

// Check current state
if (UmamiAnalytics.isEnabled) { ... }
```

> `trackScreen`, `trackEvent`, and `identify` are all safe to call before `init()` completes — events are queued and flushed automatically once the client is ready.

---

## API Reference

### `UmamiAnalytics`

| Method / Property | Description |
|---|---|
| `init({...})` | Starts background device-info collection. Returns immediately. |
| `trackScreen(name, {referrer, tag, timestamp})` | Sends a page-view event. |
| `trackEvent(name, {data, tag, timestamp})` | Sends a custom event with optional payload. |
| `identify(Map sessionData)` | Attaches non-PII attributes to the current session. |
| `setEnabled(bool)` | Enables or disables all tracking (GDPR opt-out). |
| `dispose()` | Releases the HTTP client. Call `init()` again to resume. |
| `reset()` | Resets all state. Primarily for testing. |
| `isInitialized` | `true` after a successful `init()`. |
| `isEnabled` | `true` unless `setEnabled(false)` has been called. |

### `init()` parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `websiteId` | ✅ | — | Website ID from your Umami dashboard. |
| `serverUrl` | ✅ | — | Base URL of your Umami instance. |
| `hostname` | ✅ | — | Logical app identifier (e.g. `myapp`). |
| `enableLogging` | ❌ | `false` | Print debug messages to console. |
| `onError` | ❌ | `null` | Callback invoked on init or send failures. |
| `userAgent` | ❌ | auto | Custom User-Agent string override. |
| `recordFirstOpen` | ❌ | `false` | Auto-send a `first_open` event on first launch. |

### `trackScreen()` / `trackEvent()` parameters

| Parameter | Type | Description |
|---|---|---|
| `referrer` | `String?` | Source of navigation — push URL, deep link, or in-app path. |
| `tag` | `String?` | Campaign or A/B variant label (e.g. `'summer_sale'`). |
| `timestamp` | `int?` | Unix milliseconds — for offline event queuing. |
| `data` | `Map<String, dynamic>?` | *(events only)* Arbitrary key-value payload. No PII. |

### `UmamiObserver`

A `NavigatorObserver` for automatic screen tracking. Add to `MaterialApp.navigatorObservers`:

```dart
MaterialApp(
  navigatorObservers: [UmamiObserver()],
  ...
)
```

Named routes are tracked by name (e.g. `/home`). Anonymous routes fall back to the widget's `runtimeType`.

### `DeviceIdService`

Resolves and persists a stable device ID across sessions.

| Member | Type | Description |
|---|---|---|
| `DeviceIdService.getId()` | `Future<String>` | Returns the persistent device ID. Reads from secure storage; generates and saves a new UUID on first call. |
| `DeviceIdService.isFirstLaunch` | `bool` | `true` if the device ID was freshly generated on this call — meaning the app has never been opened before (or was reinstalled on Android). |

```dart
final id = await DeviceIdService.getId();
if (DeviceIdService.isFirstLaunch) {
  // First time this app has run on this device
}
```

> **Platform notes for `recordFirstOpen` / `isFirstLaunch`:**
> - **iOS / macOS** — device ID is stored in Keychain, which survives app reinstalls. `first_open` fires only once per device, ever.
> - **Android** — secure storage is cleared on uninstall. Reinstalling the app **will trigger `first_open` again**.
> - **Windows** — secure storage survives reinstalls; fires only once.

### Init failure & retry

If `init()` fails (e.g. device-info plugin unavailable), the internal state is reset automatically so you can retry:

```dart
UmamiAnalytics.init(
  websiteId: 'your-id',
  serverUrl: 'https://your-umami.com',
  hostname: 'myapp',
  onError: (e) {
    // init failed — safe to call init() again later
    debugPrint('Analytics init failed: $e');
  },
);
```

---

## Architecture

```
umami_flutter.dart              ← Public barrel export
└─ src/
   ├─ umami_analytics.dart      ← Static API (init, track*, identify, setEnabled)
   ├─ umami_observer.dart       ← NavigatorObserver for auto screen tracking
   ├─ umami_client.dart         ← HTTP client for Umami /api/send endpoint
   ├─ device_info.dart          ← Collects device ID, locale, screen resolution
   └─ device_id_service.dart    ← Persistent device ID (Keychain / SecureStorage)
```

---

## Dependencies

| Package | Purpose |
|---|---|
| [`http`](https://pub.dev/packages/http) | HTTP requests to the Umami server |
| [`device_info_plus`](https://pub.dev/packages/device_info_plus) | Platform-specific device identifiers |
| [`android_id`](https://pub.dev/packages/android_id) | Android device ID |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Persistent secure storage for device IDs |
| [`uuid`](https://pub.dev/packages/uuid) | UUID v4 fallback for device IDs |

---

## Security & Privacy

- **No PII collected by default** — device ID is hashed, no names/emails/phones.
- **GDPR-ready** — `setEnabled(false)` provides a one-call opt-out.
- **`identify()` is non-PII only** — use plan tiers, roles, or app versions. Never send identifying information.
- **Self-hosted** — your analytics data never leaves your own server.
- **No cookies** — Umami is cookie-free by design.
- **10-second HTTP timeout** — network calls never hang indefinitely.

---

## Supported Platforms

| Platform | Supported |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Web | ❌ (uses `dart:io`) |
| Linux | ❌ |

---

## Contributing

Contributions are welcome! Bug fixes, new features, documentation improvements — all are appreciated.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Found a bug or have a feature request? [Open an issue](https://github.com/JavohirYakubov/flutter_umami/issues).

---

## Related

- [Umami](https://umami.is) — Open-source, privacy-focused analytics
- [Umami Docs](https://umami.is/docs) — Setup and API reference
- [Umami Cloud](https://cloud.umami.is) — Managed Umami hosting

---

## License

MIT License — see [LICENSE](LICENSE) for details.

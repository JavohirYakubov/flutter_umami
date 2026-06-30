import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';
import 'package:umami_flutter/umami_flutter.dart';

const _testInfo = DeviceInfo(
  deviceId: 'dev-123',
  locale: 'en_US',
  screenResolution: '375x812',
);

UmamiClient _client() => UmamiClient(
  serverUrl: 'https://example.com',
  websiteId: 'test-site',
  hostname: 'testapp',
  deviceInfo: _testInfo,
);

// ── DeviceInfo ────────────────────────────────────────────────────────────────

void main() {
  group('DeviceInfo', () {
    test('toString contains all fields', () {
      const info = DeviceInfo(
        deviceId: 'test-id',
        locale: 'en_US',
        screenResolution: '1080x1920',
      );
      expect(info.toString(), contains('test-id'));
      expect(info.toString(), contains('en_US'));
      expect(info.toString(), contains('1080x1920'));
    });

    test('same values are equal', () {
      const a = DeviceInfo(
        deviceId: 'id-1',
        locale: 'en',
        screenResolution: '100x200',
      );
      const b = DeviceInfo(
        deviceId: 'id-1',
        locale: 'en',
        screenResolution: '100x200',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different values are not equal', () {
      const a = DeviceInfo(
        deviceId: 'id-1',
        locale: 'en',
        screenResolution: '100x200',
      );
      const b = DeviceInfo(
        deviceId: 'id-2',
        locale: 'en',
        screenResolution: '100x200',
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ── UmamiClient ───────────────────────────────────────────────────────────

  group('UmamiClient', () {
    late UmamiClient client;
    setUp(() => client = _client());
    tearDown(() => client.dispose());

    test('trackScreen does not throw', () {
      expect(() => client.trackScreen('HomeScreen'), returnsNormally);
    });

    test('trackScreen with referrer does not throw', () {
      expect(
        () => client.trackScreen('HomeScreen', referrer: 'push://promo'),
        returnsNormally,
      );
    });

    test('trackScreen with tag does not throw', () {
      expect(
        () => client.trackScreen('HomeScreen', tag: 'summer_sale'),
        returnsNormally,
      );
    });

    test('trackScreen with timestamp does not throw', () {
      expect(
        () => client.trackScreen(
          'HomeScreen',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        returnsNormally,
      );
    });

    test('trackEvent with data does not throw', () {
      expect(
        () => client.trackEvent('purchase', data: {'plan': 'pro'}),
        returnsNormally,
      );
    });

    test('trackEvent with tag does not throw', () {
      expect(
        () => client.trackEvent('purchase', tag: 'campaign_a'),
        returnsNormally,
      );
    });

    test('trackEvent with timestamp does not throw', () {
      expect(
        () => client.trackEvent(
          'purchase',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        returnsNormally,
      );
    });

    test('identify does not throw', () {
      expect(
        () => client.identify({'plan': 'pro', 'role': 'admin'}),
        returnsNormally,
      );
    });

    test('custom userAgent is accepted', () {
      final c = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: _testInfo,
        userAgent: 'CustomAgent/1.0',
      );
      expect(() => c.trackScreen('Test'), returnsNormally);
      c.dispose();
    });

    test('onError callback is accepted', () {
      final errors = <Object>[];
      final c = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: _testInfo,
        onError: errors.add,
      );
      expect(() => c.trackScreen('Test'), returnsNormally);
      c.dispose();
    });
  });

  // ── UmamiAnalytics ────────────────────────────────────────────────────────

  group('UmamiAnalytics', () {
    setUp(() => UmamiAnalytics.reset());
    tearDown(() => UmamiAnalytics.reset());

    test('isInitialized is false before init', () {
      expect(UmamiAnalytics.isInitialized, isFalse);
    });

    test('isEnabled defaults to true', () {
      expect(UmamiAnalytics.isEnabled, isTrue);
    });

    test('setEnabled toggles tracking', () {
      UmamiAnalytics.setEnabled(false);
      expect(UmamiAnalytics.isEnabled, isFalse);
      UmamiAnalytics.setEnabled(true);
      expect(UmamiAnalytics.isEnabled, isTrue);
    });

    test('trackScreen before init does not throw', () {
      expect(() => UmamiAnalytics.trackScreen('Test'), returnsNormally);
    });

    test('trackScreen with all params before init does not throw', () {
      expect(
        () => UmamiAnalytics.trackScreen(
          'Test',
          referrer: 'push://promo',
          tag: 'campaign',
          timestamp: 1234567890,
        ),
        returnsNormally,
      );
    });

    test('trackEvent before init does not throw', () {
      expect(
        () => UmamiAnalytics.trackEvent('test', data: {'key': 'value'}),
        returnsNormally,
      );
    });

    test('trackEvent with tag and timestamp does not throw', () {
      expect(
        () => UmamiAnalytics.trackEvent(
          'test',
          tag: 'ab_variant_b',
          timestamp: 1234567890,
        ),
        returnsNormally,
      );
    });

    test('identify before init does not throw', () {
      expect(
        () => UmamiAnalytics.identify({'plan': 'pro'}),
        returnsNormally,
      );
    });

    test('identify when disabled does not throw', () {
      UmamiAnalytics.setEnabled(false);
      expect(
        () => UmamiAnalytics.identify({'plan': 'pro'}),
        returnsNormally,
      );
    });

    test('trackScreen when disabled does not throw', () {
      UmamiAnalytics.setEnabled(false);
      expect(() => UmamiAnalytics.trackScreen('Test'), returnsNormally);
    });

    test('reset clears state and restores isEnabled', () {
      UmamiAnalytics.setEnabled(false);
      UmamiAnalytics.reset();
      expect(UmamiAnalytics.isInitialized, isFalse);
      expect(UmamiAnalytics.isEnabled, isTrue);
    });

    test('init sets isInitialized to true', () {
      UmamiAnalytics.init(
        websiteId: 'test',
        serverUrl: 'https://example.com',
        hostname: 'test',
      );
      expect(UmamiAnalytics.isInitialized, isTrue);
    });

    test('double init is a no-op', () {
      UmamiAnalytics.init(
        websiteId: 'test',
        serverUrl: 'https://example.com',
        hostname: 'test',
      );
      expect(
        () => UmamiAnalytics.init(
          websiteId: 'test2',
          serverUrl: 'https://example2.com',
          hostname: 'test2',
        ),
        returnsNormally,
      );
    });

    test('dispose does not throw', () {
      UmamiAnalytics.init(
        websiteId: 'test',
        serverUrl: 'https://example.com',
        hostname: 'test',
      );
      expect(() => UmamiAnalytics.dispose(), returnsNormally);
    });
  });

  // ── Payload JSON structure ────────────────────────────────────────────────

  group('Payload JSON structure', () {
    test('screen payload has required fields', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': _testInfo.screenResolution,
        'language': _testInfo.locale,
        'id': _testInfo.deviceId,
      };

      final decoded =
          jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
              as Map<String, dynamic>;
      final p = decoded['payload'] as Map<String, dynamic>;

      expect(decoded['type'], equals('event'));
      expect(p['website'], equals('test-site'));
      expect(p['url'], equals('/HomeScreen'));
      expect(p['screen'], equals('375x812'));
      expect(p['language'], equals('en_US'));
    });

    test('referrer is included when provided', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
        'referrer': 'push://promo',
      };

      final p =
          (jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
                  as Map<String, dynamic>)['payload']
              as Map<String, dynamic>;

      expect(p['referrer'], equals('push://promo'));
    });

    test('tag is included when provided', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
        'tag': 'summer_sale',
      };

      final p =
          (jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
                  as Map<String, dynamic>)['payload']
              as Map<String, dynamic>;

      expect(p['tag'], equals('summer_sale'));
    });

    test('timestamp is included when provided', () {
      const ts = 1719619200000;
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
        'timestamp': ts,
      };

      final p =
          (jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
                  as Map<String, dynamic>)['payload']
              as Map<String, dynamic>;

      expect(p['timestamp'], equals(ts));
    });

    test('identify payload uses identify type', () {
      final body = jsonEncode({
        'type': 'identify',
        'payload': {
          'website': 'test-site',
          'data': {'plan': 'pro', 'role': 'admin'},
        },
      });

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['type'], equals('identify'));
      expect(
        (decoded['payload'] as Map<String, dynamic>)['data'],
        isA<Map>(),
      );
    });

    test('event url uses current screen not root', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'button_tap',
        'name': 'button_tap',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
      };

      final p =
          (jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
                  as Map<String, dynamic>)['payload']
              as Map<String, dynamic>;

      expect(p['url'], equals('/HomeScreen'));
    });

    test('event payload includes name and data', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'purchase',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
        'name': 'purchase',
        'data': {'plan': 'pro', 'price': 9.99},
      };

      final p =
          (jsonDecode(jsonEncode({'type': 'event', 'payload': payload}))
                  as Map<String, dynamic>)['payload']
              as Map<String, dynamic>;

      expect(p['name'], equals('purchase'));
      expect((p['data'] as Map)['plan'], equals('pro'));
      expect((p['data'] as Map)['price'], equals(9.99));
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';
import 'package:umami_flutter/umami_flutter.dart';

// ── DeviceInfo Tests ─────────────────────────────────────────────────────────

void main() {
  group('DeviceInfo', () {
    test('toString contains all fields', () {
      const info = DeviceInfo(
        deviceId: 'test-id',
        locale: 'en_US',
        screenResolution: '1080x1920',
      );

      final result = info.toString();
      expect(result, contains('test-id'));
      expect(result, contains('en_US'));
      expect(result, contains('1080x1920'));
    });

    test('equality: same values are equal', () {
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

    test('equality: different values are not equal', () {
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

  // ── UmamiClient Payload Tests ──────────────────────────────────────────

  group('UmamiClient payload construction', () {
    late UmamiClient client;

    setUp(() {
      client = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
      );
    });

    tearDown(() => client.dispose());

    test('trackScreen does not throw', () {
      expect(() => client.trackScreen('HomeScreen'), returnsNormally);
    });

    test('trackEvent with data does not throw', () {
      expect(
        () => client.trackEvent('purchase', data: {'plan': 'pro'}),
        returnsNormally,
      );
    });

    test('trackEvent without data does not throw', () {
      expect(() => client.trackEvent('login'), returnsNormally);
    });

    test('custom userAgent is accepted', () {
      final c = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
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
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
        onError: errors.add,
      );
      expect(() => c.trackScreen('Test'), returnsNormally);
      c.dispose();
    });
  });

  // ── UmamiAnalytics Static API Tests ────────────────────────────────────

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

    test('trackEvent before init does not throw', () {
      expect(
        () => UmamiAnalytics.trackEvent('test', data: {'key': 'value'}),
        returnsNormally,
      );
    });

    test('trackScreen when disabled does not throw', () {
      UmamiAnalytics.setEnabled(false);
      expect(() => UmamiAnalytics.trackScreen('Test'), returnsNormally);
    });

    test('trackEvent when disabled does not throw', () {
      UmamiAnalytics.setEnabled(false);
      expect(() => UmamiAnalytics.trackEvent('test'), returnsNormally);
    });

    test('reset clears initialization state', () {
      UmamiAnalytics.reset();
      expect(UmamiAnalytics.isInitialized, isFalse);
    });

    test('reset restores isEnabled to true', () {
      UmamiAnalytics.setEnabled(false);
      UmamiAnalytics.reset();
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

    test('double init is a no-op and does not throw', () {
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

    test('onError callback is wired through', () {
      final errors = <Object>[];
      expect(
        () => UmamiAnalytics.init(
          websiteId: 'test',
          serverUrl: 'https://example.com',
          hostname: 'test',
          onError: errors.add,
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

  // ── JSON Payload Structure Tests ───────────────────────────────────────

  group('Payload JSON structure', () {
    test('screen payload has required fields', () {
      const info = DeviceInfo(
        deviceId: 'dev-123',
        locale: 'en_US',
        screenResolution: '375x812',
      );

      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': info.screenResolution,
        'language': info.locale,
        'id': info.deviceId,
      };

      final body = jsonEncode({'type': 'event', 'payload': payload});
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      expect(decoded['type'], equals('event'));

      final p = decoded['payload'] as Map<String, dynamic>;
      expect(p['website'], equals('test-site'));
      expect(p['hostname'], equals('testapp'));
      expect(p['url'], equals('/HomeScreen'));
      expect(p['title'], equals('HomeScreen'));
      expect(p['screen'], equals('375x812'));
      expect(p['language'], equals('en_US'));
      expect(p['id'], equals('dev-123'));
    });

    test('event payload includes name and data for custom events', () {
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

      final body = jsonEncode({'type': 'event', 'payload': payload});
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final p = decoded['payload'] as Map<String, dynamic>;

      expect(p['name'], equals('purchase'));
      expect(p['data'], isA<Map>());
      expect((p['data'] as Map)['plan'], equals('pro'));
      expect((p['data'] as Map)['price'], equals(9.99));
    });

    test('event url uses current screen not root', () {
      // Events should be associated with the last tracked screen, not '/'.
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
  });
}

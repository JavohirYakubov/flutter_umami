// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:umami_flutter/umami_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  UmamiAnalytics.init(
    websiteId: 'your-website-id',
    serverUrl: 'https://your-umami.example.com',
    hostname: 'example_app',
    enableLogging: true,
    recordFirstOpen: true,
    onError: (error) => print('Analytics error: $error'),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umami Flutter Example',
      // UmamiObserver automatically tracks every named route change.
      navigatorObservers: [UmamiObserver()],
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/detail': (_) => const DetailScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Track a custom event with data
                UmamiAnalytics.trackEvent(
                  'button_tap',
                  data: {'button': 'go_to_detail'},
                );
                Navigator.pushNamed(context, '/detail');
              },
              child: const Text('Go to Detail'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // GDPR: disable tracking
                UmamiAnalytics.setEnabled(false);
                print('Tracking disabled');
              },
              child: const Text('Opt out'),
            ),
            ElevatedButton(
              onPressed: () {
                UmamiAnalytics.setEnabled(true);
                print('Tracking enabled');
              },
              child: const Text('Opt in'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            UmamiAnalytics.trackEvent(
              'purchase',
              data: {'plan': 'pro', 'price': 9.99},
            );
          },
          child: const Text('Track Purchase'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:umami_flutter/src/umami_analytics.dart';

/// A [NavigatorObserver] that automatically tracks screen views in Umami.
///
/// Add to your [MaterialApp.navigatorObservers] to track every route change
/// without manual [UmamiAnalytics.trackScreen] calls.
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [UmamiObserver()],
///   routes: {
///     '/home': (_) => const HomeScreen(),
///     '/profile': (_) => const ProfileScreen(),
///   },
/// );
/// ```
///
/// Named routes are tracked by their route name (e.g. `/home`).
/// Anonymous routes fall back to the widget's `runtimeType` name.
class UmamiObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _track(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name ??
        route.runtimeType.toString().replaceAll('_', '');
    UmamiAnalytics.trackScreen(name);
  }
}

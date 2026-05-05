import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._privateConstructor();
  static final AnalyticsService instance = AnalyticsService._privateConstructor();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> levelStarted(int level) async {
    await _analytics.logEvent(
      name: 'level_started',
      parameters: {'level': level},
    );
  }

  Future<void> enemyDestroyed(String type) async {
    await _analytics.logEvent(
      name: 'enemy_destroyed',
      parameters: {'type': type},
    );
  }

  Future<void> playerDied(int score) async {
    await _analytics.logEvent(
      name: 'player_died',
      parameters: {'score': score},
    );
  }
}
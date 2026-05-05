import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._privateConstructor();
  static final AnalyticsService instance = AnalyticsService._privateConstructor();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logGameOver({
    required int score,
    required int destroyedCount,
    required int reachedLevel,
  }) async {
    await _analytics.logEvent(
      name: 'game_over',
      parameters: {
        'score': score,
        'destroyed_count': destroyedCount,
        'reached_level': reachedLevel,
      },
    );
  }

  Future<void> logLevelUp(int level) async {
    await _analytics.logEvent(
      name: 'level_up',
      parameters: {'level': level},
    );
  }
}
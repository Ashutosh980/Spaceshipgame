import 'package:firebase_performance/firebase_performance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceService {
  PerformanceService._privateConstructor();
  static final PerformanceService instance = PerformanceService._privateConstructor();

  static const _consentKey = 'performance_collection_consent';

  final Map<String, Trace> _activeTraces = {};

  /// Lazy — Firebase must be initialized before first access.
  FirebasePerformance get _performance => FirebasePerformance.instance;

  /// Reads stored consent; defaults to true until a GDPR flow is wired in.
  Future<bool> loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? true;
  }

  Future<void> setConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, enabled);
    await setCollectionEnabled(enabled);
  }

  /// Enable or disable performance collection based on GDPR/UMP consent
  Future<void> setCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }

  /// Start a custom trace (e.g., 'level_load', 'combo_32x_loop')
  Future<void> startTrace(String traceName) async {
    if (_activeTraces.containsKey(traceName)) return;

    final trace = _performance.newTrace(traceName);
    await trace.start();
    _activeTraces[traceName] = trace;
  }

  /// Stop a custom trace
  Future<void> stopTrace(String traceName) async {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      await trace.stop();
      _activeTraces.remove(traceName);
    }
  }

  /// Add a custom attribute to an active trace (e.g., 'enemy_count': '50')
  void addTraceAttribute(String traceName, String key, String value) {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.putAttribute(key, value);
    }
  }

  /// Increment a custom metric on an active trace (e.g., 'frames_dropped')
  void incrementMetric(String traceName, String metricName, int value) {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.incrementMetric(metricName, value);
    }
  }

  /// Track a custom HTTP Request manually (Useful if using Dio or http package)
  Future<HttpMetric> trackHttpRequest(String url, HttpMethod method) async {
    final metric = _performance.newHttpMetric(url, method);
    await metric.start();
    return metric;
  }
}

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteConfigService {
  RemoteConfigService._privateConstructor();
  static final RemoteConfigService instance = RemoteConfigService._privateConstructor();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Adjust as needed
      ));
      await _remoteConfig.setDefaults(const {
        'min_version': '1.0.0',
        'base_difficulty': 1,
        'special_events': '[{"title": "Welcome Pilot", "description": "Defeat the invading aliens!", "imageUrl": ""}]',
      });
      await _remoteConfig.fetchAndActivate();
    } catch (e, stackTrace) {
      // Log non-fatal error to Crashlytics manually if fetch fails
      FirebaseCrashlytics.instance.recordError(
        Exception('Remote Config fetch failed: $e'),
        stackTrace,
        reason: 'Failed to initialize remote config',
        fatal: false,
      );
    }
  }

  int get baseDifficulty {
    return _remoteConfig.getInt('base_difficulty');
  }

  String get specialEventsJson {
    return _remoteConfig.getString('special_events');
  }

  Future<void> checkForUpdate(BuildContext context) async {
    final minVersionStr = _remoteConfig.getString('min_version');
    if (minVersionStr.isEmpty) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionStr = packageInfo.version;

    if (
      _isUpdateRequired(currentVersionStr, minVersionStr)
    ) {
      if (context.mounted) {
        _showForceUpdateDialog(context);
      }
    }
  }

  bool _isUpdateRequired(String currentVersion, String minVersion) {
    final currentParts = currentVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final minParts = minVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < minParts.length; i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final min = minParts[i];
      if (current < min) return true;
      if (current > min) return false;
    }
    return false;
  }

  void _showForceUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevents Android back button dismissal
          child: AlertDialog(
            title: const Text('Update Required'),
            content: const Text('A new version of Galaxy Fighter is available. Please update to continue playing.'),
            actions: [
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse('market://details?id=com.ace.galaxyfighter');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    // Fallback to web URL if Play Store is not installed
                    await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.ace.galaxyfighter'));
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}
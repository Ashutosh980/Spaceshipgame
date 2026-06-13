import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'utils/firebase_options.dart';
import 'utils/remote_config_service.dart';
import 'utils/storage_service.dart';
import 'utils/settings_provider.dart';
import 'utils/user_service.dart';
import 'utils/performance_service.dart';
import 'game.dart';
import 'overlays/main_menu_overlay.dart';
import 'overlays/pause_menu_overlay.dart';
import 'overlays/game_over_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await PerformanceService.instance.startTrace('app_start_to_interactive');

  await StorageService().init();
  await RemoteConfigService.instance.initialize();
  await UserService().init();

  final settingsProvider = SettingsProvider.instance;
  await settingsProvider.init();

  final hasConsent = await PerformanceService.instance.loadConsent();
  await PerformanceService.instance.setCollectionEnabled(hasConsent);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = GalaxyFighterGame();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (game.state == GameState.playing) {
              game.pauseGame();
            } else if (game.state == GameState.paused) {
              game.resumeGame();
            }
          },
          child: GameWidget(
            game: game,
            initialActiveOverlays: const ['MainMenu'],
            overlayBuilderMap: {
              'MainMenu': (context, game) =>
                  MainMenuOverlay(game: game as GalaxyFighterGame),
              'GameOver': (context, game) =>
                  GameOverOverlay(game: game as GalaxyFighterGame),
              'PauseMenu': (context, game) =>
                  PauseMenuOverlay(game: game as GalaxyFighterGame),
            },
          ),
        ),
      ),
    ),
  );
}

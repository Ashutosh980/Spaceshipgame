import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'utils/firebase_options.dart';
import 'utils/remote_config_service.dart';
import 'utils/storage_service.dart';
import 'utils/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Services
  await StorageService().init();
  await RemoteConfigService.instance.initialize();

  final settingsProvider = SettingsProvider.instance;
  await settingsProvider.init();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GameWidget(
          game: GalaxyFighterGame(),
          initialActiveOverlays: const ['MainMenu'],
          overlayBuilderMap: {
            'MainMenu': (context, game) {
              return MainMenuOverlay(game: game as GalaxyFighterGame);
            },
            'GameOver': (context, game) {
              return GameOverOverlay(game: game as GalaxyFighterGame);
            },
          },
        ),
      ),
    ),
  );
}

class MainMenuOverlay extends StatefulWidget {
  final GalaxyFighterGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  @override
  void initState() {
    super.initState();
    // Check for updates after the first frame is rendered to ensure
    // context is available for showing a dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        RemoteConfigService.instance.checkForUpdate(context);
      }
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF00E676), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('SETTINGS', style: TextStyle(color: Color(0xFF00E676), letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Background Music', style: TextStyle(color: Colors.white, fontSize: 18)),
                  activeColor: const Color(0xFF00E676),
                  value: settings.musicEnabled,
                  onChanged: (val) => settings.toggleMusic(),
                ),
                SwitchListTile(
                  title: const Text('Sound Effects (SFX)', style: TextStyle(color: Colors.white, fontSize: 18)),
                  activeColor: const Color(0xFF00E676),
                  value: settings.sfxEnabled,
                  onChanged: (val) => settings.toggleSfx(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      );
    });
  }

  void _showHallOfFameDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFFAB00), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('HALL OF FAME', style: TextStyle(color: Color(0xFFFFAB00), letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: Color(0xFFFFAB00))));
            final prefs = snapshot.data!;
            final scores = prefs.getStringList('top_scores') ?? [];
            if (scores.isEmpty) {
              return const Text('No scores yet. Play a game to rank up!', style: TextStyle(color: Colors.white));
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Text('#${index + 1}', style: const TextStyle(color: Color(0xFFFFAB00), fontSize: 20, fontWeight: FontWeight.bold)),
                    title: Text('${scores[index]}         PTS', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.star, color: Color(0xFFFFAB00), size: 32),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      );
    });
  }

  void _showSpecialEventsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      final jsonStr = RemoteConfigService.instance.specialEventsJson;
      List<dynamic> events = [];
      try {
        events = jsonDecode(jsonStr);
      } catch(e) {
        // Fallback for JSON parse errors
      }

      return AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFD500F9), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('SPECIAL EVENTS', style: TextStyle(color: Color(0xFFD500F9), letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: events.isEmpty 
            ? const Text('No special events right now.', style: TextStyle(color: Colors.white))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    color: Colors.white.withAlpha(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty
                          ? Image.network(event['imageUrl'], width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.event, color: Color(0xFFD500F9)))
                          : const Icon(Icons.event, color: Color(0xFFD500F9), size: 32),
                      title: Text(event['title'] ?? 'Event', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(event['description'] ?? '', style: TextStyle(color: Colors.white.withAlpha(180))),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      );
    });
  }

  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/ship.png', width: 140, height: 140),
            const SizedBox(height: 10),
            const Text(
              'GALAXY FIGHTER',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            
            _MenuButton(
              title: 'START GAME',
              color: const Color(0xFF00E5FF),
              onTap: widget.game.restart,
            ),
            _MenuButton(
              title: 'HALL OF FAME',
              color: const Color(0xFFFFAB00),
              onTap: () => _showHallOfFameDialog(context),
            ),
            _MenuButton(
              title: 'SPECIAL EVENTS',
              color: const Color(0xFFD500F9),
              onTap: () => _showSpecialEventsDialog(context),
            ),
            _MenuButton(
              title: 'SETTINGS',
              color: const Color(0xFF00E676),
              onTap: () => _showSettingsDialog(context),
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 30),
              // QA Crash Test Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  FirebaseCrashlytics.instance.crash();
                },
                child: const Text('FORCE CRASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _MenuButton({required this.title, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 12)],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final GalaxyFighterGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1B2A).withAlpha(240),
                const Color(0xFF1B263B).withAlpha(240),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E5FF).withAlpha(100),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withAlpha(40),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💥 GAME OVER 💥',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: Color(0xFFFF1744), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _statRow('SCORE', '${game.score}', const Color(0xFF00E5FF)),
              const SizedBox(height: 8),
              _statRow(
                  'HIGH SCORE', '${game.highScore}', const Color(0xFFFFAB00)),
              const SizedBox(height: 8),
              _statRow('DESTROYED', '${game.destroyedCount}',
                  const Color(0xFFFF6D00)),
              const SizedBox(height: 8),
              _statRow(
                  'LEVEL', '${game.difficultyLevel}', const Color(0xFF00E676)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: game.restart,
                    child: _buildButton('🚀 RESTART', const [Color(0xFF00B0FF), Color(0xFF00E5FF)]),
                  ),
                  // Target overlay for later 'Music' and 'Leaderboards' integrations
                  GestureDetector(
                    onTap: game.goToMainMenu,
                    child: _buildButton('🏠 MENU', const [Color(0xFF651FFF), Color(0xFF00E676)]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withAlpha(100), blurRadius: 16),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

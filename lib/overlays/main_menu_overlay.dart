import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game.dart';
import '../utils/remote_config_service.dart';
import '../utils/settings_provider.dart';
import '../utils/user_service.dart';
import '../utils/cloud_service.dart';
import 'menu_button.dart';

class MainMenuOverlay extends StatefulWidget {
  final GalaxyFighterGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        RemoteConfigService.instance.checkForUpdate(context);
      }
    });
  }

  Future<void> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasSavedGame = prefs.getBool('has_saved_game') ?? false;
      });
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF00E676), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'SETTINGS',
            style: TextStyle(
              color: Color(0xFF00E676),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Background Music',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    activeColor: const Color(0xFF00E676),
                    value: settings.musicEnabled,
                    onChanged: (val) => settings.toggleMusic(),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Sound Effects (SFX)',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
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
              child: const Text(
                'CLOSE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHallOfFameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D1B2A),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFFFAB00), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HALL OF FAME',
                    style: TextStyle(
                      color: Color(0xFFFFAB00),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () async {
                      String tempName = UserService().userName;
                      final String? newName = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF0D1B2A),
                            title: const Text(
                              'Edit Pilot Name',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFFFAB00)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFFFAB00)),
                                ),
                              ),
                              onChanged: (val) => tempName = val,
                              controller: TextEditingController(text: tempName),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, tempName),
                                child: const Text(
                                  'SAVE',
                                  style: TextStyle(color: Color(0xFFFFAB00)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (newName != null && newName.trim().isNotEmpty) {
                        await UserService().updateUserName(newName.trim());
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              content: FutureBuilder<List<Map<String, dynamic>>>(
                future: CloudService().fetchHallOfFame(forceRefresh: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFFFFAB00)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Failed to connect to galactic comms. Please check your network.',
                      style: TextStyle(color: Colors.redAccent),
                    );
                  }
                  final scores = snapshot.data ?? [];
                  if (scores.isEmpty) {
                    return const Text(
                      'No pilots in the Hall of Fame yet.',
                      style: TextStyle(color: Colors.white),
                    );
                  }
                  return SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: scores.length,
                      itemBuilder: (context, index) {
                        final data = scores[index];
                        final bool isMe = data['id'] == UserService().deviceId;
                        final rankColors = [
                          const Color(0xFFFFD700),
                          const Color(0xFFC0C0C0),
                          const Color(0xFFCD7F32),
                        ];
                        final rankColor = index < 3
                            ? rankColors[index]
                            : const Color(0xFFFFAB00);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: isMe
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF00E676),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF00E676).withOpacity(0.1),
                                )
                              : null,
                          child: ListTile(
                            leading: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: rankColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Text(
                              data['userName'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${data['highScore']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSpecialEventsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final jsonStr = RemoteConfigService.instance.specialEventsJson;
        List<dynamic> events = [];
        try {
          events = jsonDecode(jsonStr);
        } catch (e) {
          // Fallback for JSON parse errors
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFD500F9), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'SPECIAL EVENTS',
            style: TextStyle(
              color: Color(0xFFD500F9),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: events.isEmpty
                ? const Text(
                    'No special events right now.',
                    style: TextStyle(color: Colors.white),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        color: Colors.white.withAlpha(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: event['imageUrl'] != null &&
                                  event['imageUrl'].toString().isNotEmpty
                              ? Image.network(
                                  event['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.event,
                                    color: Color(0xFFD500F9),
                                  ),
                                )
                              : const Icon(
                                  Icons.event,
                                  color: Color(0xFFD500F9),
                                  size: 32,
                                ),
                          title: Text(
                            event['title'] ?? 'Event',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            event['description'] ?? '',
                            style: TextStyle(color: Colors.white.withAlpha(180)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
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
            if (widget.game.state == GameState.paused || _hasSavedGame)
              MenuButton(
                title: 'RESUME GAME',
                color: const Color(0xFF00B0FF),
                onTap: widget.game.resumeFromMenu,
              ),
            MenuButton(
              title: 'START GAME',
              color: const Color(0xFF00E5FF),
              onTap: widget.game.restart,
            ),
            MenuButton(
              title: 'HALL OF FAME',
              color: const Color(0xFFFFAB00),
              onTap: () => _showHallOfFameDialog(context),
            ),
            MenuButton(
              title: 'SPECIAL EVENTS',
              color: const Color(0xFFD500F9),
              onTap: () => _showSpecialEventsDialog(context),
            ),
            MenuButton(
              title: 'SETTINGS',
              color: const Color(0xFF00E676),
              onTap: () => _showSettingsDialog(context),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  FirebaseCrashlytics.instance.crash();
                },
                child: const Text(
                  'FORCE CRASH',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_audio/flame_audio.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider instance = SettingsProvider._internal();
  factory SettingsProvider() => instance;
  SettingsProvider._internal();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);
    notifyListeners();

    // Toggle background music instantly
    if (_musicEnabled) {
      FlameAudio.bgm.play('bgm.mp3', volume: 0.5);
    } else {
      FlameAudio.bgm.stop();
    }
  }

  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', _sfxEnabled);
    notifyListeners();
  }
}
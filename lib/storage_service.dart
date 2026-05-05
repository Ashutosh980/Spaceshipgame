import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int getHighScore() {
    return _prefs.getInt('high_score') ?? 0;
  }

  Future<void> setHighScore(int score) async {
    await _prefs.setInt('high_score', score);
  }
}
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String? _deviceId;
  String? _userName;

  Future<void> init() async {
    _deviceId = await _generateDeviceId();
    
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName');
    
    if (_userName == null) {
      _userName = 'Player_${_deviceId?.substring(0, 5) ?? 'Unknown'}';
      await prefs.setString('userName', _userName!);
    }
  }

  Future<String> _generateDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webBrowserInfo = await deviceInfo.webBrowserInfo;
      return webBrowserInfo.vendor ?? webBrowserInfo.userAgent ?? 'web_id';
    } else if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? 'ios_id'; 
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; 
    } else {
      return 'unknown_device_id';
    }
  }

  String get deviceId => _deviceId ?? 'unknown_device';
  String get userName => _userName ?? 'Player_Unknown';

  Future<void> updateUserName(String newName) async {
    _userName = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
  }
}

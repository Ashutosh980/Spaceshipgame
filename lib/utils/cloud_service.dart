import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudService {
  // Singleton pattern for global access
  static final CloudService _instance = CloudService._internal();
  factory CloudService() => _instance;
  CloudService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for top scores to avoid unnecessary reads during a session
  List<Map<String, dynamic>>? _cachedTopTen;

  Future<void> updateScore(String deviceId, String name, int newScore) async {
    try {
      final docRef = _firestore.collection('users').doc(deviceId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Document doesn't exist, create it
          transaction.set(docRef, {
            'userName': name,
            'highScore': newScore,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _cachedTopTen = null; // Invalidate cache
        } else {
          // Document exists, check if new score is higher
          final int existingHighScore = snapshot.data()?['highScore'] ?? 0;
          if (newScore > existingHighScore) {
            transaction.update(docRef, {
              'userName': name,
              'highScore': newScore,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            _cachedTopTen = null; // Invalidate cache
          } else if (snapshot.data()?['userName'] != name) {
             // Update username if it changed even if score didn't
             transaction.update(docRef, {
               'userName': name,
             });
             _cachedTopTen = null; // Invalidate cache to reflect name change
          }
        }
      });
      
      // Update local high score as well to keep sync
      final prefs = await SharedPreferences.getInstance();
      final localHighScore = prefs.getInt('highScore') ?? 0;
      if (newScore > localHighScore) {
         await prefs.setInt('highScore', newScore);
      }

    } catch (e) {
      // Graceful error handling - fail silently without breaking the game flow
      // ignore: avoid_print
      print("Failed to save score to cloud: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchHallOfFame({bool forceRefresh = false}) async {
    // Return cached results if available and refresh is not forced
    if (_cachedTopTen != null && !forceRefresh) {
      return _cachedTopTen!;
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('highScore', descending: true)
          .orderBy('updatedAt', descending: false)
          .limit(10)
          .get();

      _cachedTopTen = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include the device ID if needed
        return data;
      }).toList();

      return _cachedTopTen!;
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching leaderboard: $e");
      // Return empty list or fallback data on failure
      return [];
    }
  }
}

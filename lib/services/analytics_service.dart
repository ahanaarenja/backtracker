import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  
  DocumentReference? get _userDoc => _userId != null 
      ? _firestore.collection('Users').doc(_userId) 
      : null;

  /// Save exercise session - just adds time and updates accuracy if higher
  Future<void> saveExerciseSession({
    required int durationMinutes,
    required double accuracy,
  }) async {
    if (_userDoc == null) return;

    final today = _getDateString(DateTime.now());
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_userDoc!);
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      // Get existing daily stats or create new
      Map<String, dynamic> dailyStats = Map<String, dynamic>.from(data['dailyStats'] ?? {});
      
      // Get today's stats
      Map<String, dynamic> todayStats = dailyStats[today] != null 
          ? Map<String, dynamic>.from(dailyStats[today]) 
          : {'time': 0, 'accuracy': 0.0};
      
      // Add time to today's total
      int currentTime = (todayStats['time'] ?? 0) as int;
      todayStats['time'] = currentTime + durationMinutes;
      
      // Only update accuracy if new one is higher
      double currentAccuracy = (todayStats['accuracy'] ?? 0.0).toDouble();
      if (accuracy > currentAccuracy) {
        todayStats['accuracy'] = accuracy;
      }
      
      dailyStats[today] = todayStats;
      
      // Update streak
      int currentStreak = await _calculateStreak(data, today);
      
      transaction.set(_userDoc!, {
        'dailyStats': dailyStats,
        'currentStreak': currentStreak,
        'lastExerciseDate': today,
      }, SetOptions(merge: true));
    });
  }

  /// Calculate streak - simple counter logic
  Future<int> _calculateStreak(Map<String, dynamic> data, String today) async {
    String? lastExerciseDate = data['lastExerciseDate'] as String?;
    int currentStreak = (data['currentStreak'] ?? 0) as int;
    
    if (lastExerciseDate == null) {
      // First exercise ever
      return 1;
    }
    
    if (lastExerciseDate == today) {
      // Same day, streak unchanged
      return currentStreak;
    }
    
    // Check if yesterday
    final yesterday = _getDateString(DateTime.now().subtract(const Duration(days: 1)));
    
    if (lastExerciseDate == yesterday) {
      // Consecutive day, increment streak
      return currentStreak + 1;
    } else {
      // Streak broken, reset to 1
      return 1;
    }
  }

  /// Get current streak
  Future<int> getStreak() async {
    if (_userDoc == null) return 0;
    
    final doc = await _userDoc!.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Check if streak is still valid (did exercise yesterday or today)
    String? lastExerciseDate = data['lastExerciseDate'] as String?;
    if (lastExerciseDate == null) return 0;
    
    final today = _getDateString(DateTime.now());
    final yesterday = _getDateString(DateTime.now().subtract(const Duration(days: 1)));
    
    if (lastExerciseDate == today || lastExerciseDate == yesterday) {
      return (data['currentStreak'] ?? 0) as int;
    } else {
      // Streak is broken
      return 0;
    }
  }

  /// Get daily stats for chart (last 7 days)
  Future<List<DayData>> getWeeklyStats() async {
    if (_userDoc == null) return _getEmptyWeek();
    
    final doc = await _userDoc!.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, dynamic> dailyStats = Map<String, dynamic>.from(data['dailyStats'] ?? {});
    
    // Get last 7 days
    List<DayData> weekData = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = _getDateString(date);
      
      if (dailyStats.containsKey(dateStr)) {
        final dayStats = dailyStats[dateStr] as Map<String, dynamic>;
        weekData.add(DayData(
          date: date,
          time: (dayStats['time'] ?? 0) as int,
          accuracy: (dayStats['accuracy'] ?? 0.0).toDouble(),
        ));
      } else {
        weekData.add(DayData(date: date, time: 0, accuracy: 0));
      }
    }
    
    return weekData;
  }

  List<DayData> _getEmptyWeek() {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return DayData(date: date, time: 0, accuracy: 0);
    });
  }

  /// Get user's diagnosis
  Future<String?> getUserDiagnosis() async {
    if (_userDoc == null) return null;
    
    final doc = await _userDoc!.get();
    final data = doc.data() as Map<String, dynamic>?;
    
    // Diagnosis is stored as: { "diagnosis": { "diagnosis": "text", "confidence": 0.85 } }
    final diagnosisData = data?['diagnosis'];
    if (diagnosisData is Map) {
      return diagnosisData['diagnosis'] as String?;
    }
    // Fallback if stored as simple string
    return diagnosisData as String?;
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Simple data class for daily stats
class DayData {
  final DateTime date;
  final int time; // minutes
  final double accuracy; // percentage 0-100

  DayData({
    required this.date,
    required this.time,
    required this.accuracy,
  });
}

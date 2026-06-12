import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/mood/data/models/mood_model.dart';
import 'database_service.dart';
import 'sentiment_service.dart';

/// A production-ready manager that bridges local in-memory states (for previewing
/// without Firestore auth/setup) and Firestore (for production persistence).
///
/// **Clean Architecture Note:** This separates UI components from direct database access.
class MoodManager {
  // Singleton pattern for application-wide consistency
  static final MoodManager _instance = MoodManager._internal();
  factory MoodManager() => _instance;

  final DatabaseService _databaseService = DatabaseService();
  final List<MoodModel> _inMemoryLogs = [];
  
  // A broadcast stream controller that exposes the active list of mood logs
  final _moodsController = StreamController<List<MoodModel>>.broadcast();
  StreamSubscription<List<MoodModel>>? _firestoreSubscription;

  MoodManager._internal() {
    _initLocalLogs();

    // Safely listen to Firebase Auth changes to dynamically switch data sources
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _updateStreamSubscription(user);
        if (user != null) {
          syncOfflineLogsToCloud();
        }
      });
    } catch (_) {
      // Firebase not initialized or unsupported platform
      _updateStreamSubscription(null);
    }
  }

  Future<void> _initLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLoadedBefore = prefs.getBool('mood_logs_initialized') ?? false;
    
    if (!hasLoadedBefore) {
      _inMemoryLogs.addAll([
        MoodModel(
          id: 'mock_1',
          userId: 'preview_user',
          moodScore: 5,
          note: 'Sáng nay dậy sớm thiền định, cảm thấy tràn ngập năng lượng tích cực và bình yên vô ngần.',
          tags: ['Tĩnh lặng', 'Bình yên', 'Biết ơn'],
          timestamp: DateTime.now().subtract(const Duration(days: 0)),
          sentimentScore: 4.5,
        ),
        MoodModel(
          id: 'mock_2',
          userId: 'preview_user',
          moodScore: 4,
          note: 'Công việc trôi chảy, nhận được lời khen từ đồng nghiệp. Cảm xúc rất thăng hoa!',
          tags: ['Hào hứng', 'Tập trung'],
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          sentimentScore: 3.5,
        ),
        MoodModel(
          id: 'mock_3',
          userId: 'preview_user',
          moodScore: 3,
          note: 'Một ngày làm việc bình thường, không có gì nổi bật. Có hơi mỏi mắt một chút.',
          tags: ['Tập trung', 'Mệt mỏi'],
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          sentimentScore: 0.5,
        ),
        MoodModel(
          id: 'mock_4',
          userId: 'preview_user',
          moodScore: 2,
          note: 'Thời tiết mưa gió âm u làm mình hơi oải và thiếu động lực làm việc.',
          tags: ['Mệt mỏi', 'Căng thẳng'],
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          sentimentScore: -2.0,
        ),
        MoodModel(
          id: 'mock_5',
          userId: 'preview_user',
          moodScore: 4,
          note: 'Gặp gỡ bạn cũ uống cà phê tâm sự rất vui vẻ, trút bỏ được nhiều phiền muộn.',
          tags: ['Vui vẻ', 'Bình yên'],
          timestamp: DateTime.now().subtract(const Duration(days: 4)),
          sentimentScore: 3.8,
        ),
        MoodModel(
          id: 'mock_6',
          userId: 'preview_user',
          moodScore: 1,
          note: 'Tranh cãi với một người bạn khiến mình cực kỳ stress và mất ngủ cả đêm.',
          tags: ['Căng thẳng', 'Lo âu'],
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          sentimentScore: -4.5,
        ),
        MoodModel(
          id: 'mock_7',
          userId: 'preview_user',
          moodScore: 3,
          note: 'Dành cả ngày nghỉ ngơi ở nhà đọc sách, nấu một món ăn mới thanh đạm.',
          tags: ['Tĩnh lặng', 'Bình yên'],
          timestamp: DateTime.now().subtract(const Duration(days: 6)),
          sentimentScore: 4.0,
        ),
      ]);
      await _saveLocalLogsToPrefs();
      await prefs.setBool('mood_logs_initialized', true);
    } else {
      await _loadLocalLogsFromPrefs();
    }
  }

  Future<void> _saveLocalLogsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _inMemoryLogs.map((log) {
        final data = log.toFirestore();
        data['id'] = log.id;
        data['timestamp'] = log.timestamp.millisecondsSinceEpoch;
        return jsonEncode(data);
      }).toList();
      await prefs.setStringList('offline_mood_logs', jsonList);
    } catch (e) {
      debugPrint('Error saving local logs: $e');
    }
  }

  Future<void> _loadLocalLogsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('offline_mood_logs');
      if (jsonList != null) {
        _inMemoryLogs.clear();
        for (var jsonStr in jsonList) {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          _inMemoryLogs.add(MoodModel.fromMap(map, docId: map['id'] as String?));
        }
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading local logs: $e');
    }
  }

  Future<void> syncOfflineLogsToCloud() async {
    final user = _safeCurrentUser();
    if (user != null && _inMemoryLogs.isNotEmpty) {
      final nonMocks = _inMemoryLogs.where((log) => log.id != null && !log.id!.startsWith('mock_')).toList();
      for (var log in nonMocks) {
        try {
          await _databaseService.addMood(log);
        } catch (e) {
          debugPrint('Sync failed: $e');
        }
      }
      _inMemoryLogs.clear();
      await _saveLocalLogsToPrefs();
      _notifyListeners();
    }
  }

  /// Safely checks if a Firebase user is currently authenticated.
  User? _safeCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Switch subscription dynamically between Firestore and mock local fallback
  void _updateStreamSubscription(User? user) {
    _firestoreSubscription?.cancel();
    if (user != null) {
      try {
        _firestoreSubscription = _databaseService.getMoodStream().listen(
          (logs) {
            _moodsController.add(logs);
          },
          onError: (error) {
            // Fallback to local memory logs if Firestore fails/denied
            debugPrint('Firestore stream error, falling back to local: $error');
            // Use microtask to ensure broadcast listeners are subscribed before emitting
            Future.microtask(() => _emitLocalLogs());
          },
        );
      } catch (_) {
        Future.microtask(() => _emitLocalLogs());
      }
    } else {
      Future.microtask(() => _emitLocalLogs());
    }
  }

  /// Emits real-time lists of mood logs
  Stream<List<MoodModel>> get moodStream {
    final user = _safeCurrentUser();
    if (user != null) {
      try {
        // Re-subscribe to Firestore to ensure new broadcast listeners get fresh data
        _updateStreamSubscription(user);
        return _moodsController.stream;
      } catch (_) {}
    }
    // Return local list as stream immediately
    Future.microtask(() => _emitLocalLogs());
    return _moodsController.stream;
  }

  /// Always emits current in-memory logs to the stream (used as fallback)
  void _emitLocalLogs() {
    _inMemoryLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _moodsController.add(List.unmodifiable(_inMemoryLogs));
  }

  void _notifyListeners() {
    _inMemoryLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (_safeCurrentUser() == null) {
      _moodsController.add(List.unmodifiable(_inMemoryLogs));
    }
  }

  /// Check if Cloud Sync (Firebase Auth) is active
  bool get isCloudSyncEnabled {
    return _safeCurrentUser() != null;
  }

  /// Enable Cloud Sync by signing in anonymously
  Future<bool> enableCloudSync() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (userCredential.user != null) {
        _updateStreamSubscription(userCredential.user);
        return true;
      }
    } catch (e) {
      debugPrint('Error enabling Cloud Sync: $e');
    }
    return false;
  }

  /// Disable Cloud Sync by signing out
  Future<void> disableCloudSync() async {
    try {
      await FirebaseAuth.instance.signOut();
      _updateStreamSubscription(null);
    } catch (e) {
      debugPrint('Error disabling Cloud Sync: $e');
    }
  }

  /// Adds a mood log to Firebase Firestore or falls back to local in-memory storage
  Future<void> addMoodEntry({
    required int moodScore,
    required String? note,
    required List<String> tags,
  }) async {
    // 1. Analyze note sentiment using our offline VietnameseSentimentService
    double? sentiment;
    if (note != null && note.trim().isNotEmpty) {
      sentiment = VietnameseSentimentService().analyze(note);
    }

    final newLog = MoodModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _safeCurrentUser()?.uid ?? 'preview_user',
      moodScore: moodScore,
      note: note,
      tags: tags,
      timestamp: DateTime.now(),
      sentimentScore: sentiment,
    );

    // 2. Try persisting to Firebase Firestore
    bool firebaseSaved = false;
    try {
      if (_safeCurrentUser() != null) {
        await _databaseService.addMood(newLog);
        firebaseSaved = true;
      }
    } catch (e) {
      debugPrint('Failed to save to Firebase, saving locally: $e');
    }

    // 3. Keep local state in sync (ensuring smooth UX / fallback)
    if (!firebaseSaved) {
      _inMemoryLogs.add(newLog);
      await _saveLocalLogsToPrefs();
      _notifyListeners();
    }
  }

  /// Deletes a mood entry from Firebase or locally
  Future<void> deleteMoodEntry(String id) async {
    try {
      if (_safeCurrentUser() != null) {
        await _databaseService.deleteMood(id);
      }
    } catch (e) {
      debugPrint('Failed to delete from Firebase: $e');
    }

    // Delete locally as well / fallback
    _inMemoryLogs.removeWhere((log) => log.id == id);
    await _saveLocalLogsToPrefs();
    _notifyListeners();
  }

  /// Updates a mood entry locally and on Firebase
  Future<void> updateMoodEntry(MoodModel mood) async {
    double? sentiment;
    if (mood.note != null && mood.note!.trim().isNotEmpty) {
      sentiment = VietnameseSentimentService().analyze(mood.note!);
    }
    final updatedLog = mood.copyWith(sentimentScore: sentiment);

    try {
      if (_safeCurrentUser() != null) {
        await _databaseService.updateMood(updatedLog);
      }
    } catch (e) {
      debugPrint('Failed to update in Firebase: $e');
    }

    final index = _inMemoryLogs.indexWhere((log) => log.id == mood.id);
    if (index != -1) {
      _inMemoryLogs[index] = updatedLog;
      await _saveLocalLogsToPrefs();
      _notifyListeners();
    }
  }

  /// Expose the raw list of memory logs for backup/restore purposes
  List<MoodModel> get inMemoryLogs => List.unmodifiable(_inMemoryLogs);

  /// Overwrites the in-memory logs (used for data import)
  Future<void> importLogs(List<MoodModel> logs) async {
    _inMemoryLogs.clear();
    _inMemoryLogs.addAll(logs);
    await _saveLocalLogsToPrefs();
    _notifyListeners();
    
    // Attempt syncing if logged in
    if (_safeCurrentUser() != null) {
      await syncOfflineLogsToCloud();
    }
  }
}

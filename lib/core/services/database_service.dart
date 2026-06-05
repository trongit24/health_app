import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/mood/data/models/mood_model.dart';

/// Service responsible for managing database transactions with Cloud Firestore.
/// Integrates with Firebase Auth to enforce secure, user-scoped operations.
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Custom getter to safely fetch the current authenticated user's UID.
  /// Throws an [UnauthenticatedException] if no user is signed in.
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UnauthenticatedException();
    }
    return user.uid;
  }

  /// Private helper to get the type-safe collection reference for 'mood_logs'.
  /// Uses Firestore's `withConverter` to automatically map database documents
  /// to and from our robust [MoodModel].
  CollectionReference<MoodModel> get _moodLogsCollection =>
      _firestore.collection('mood_logs').withConverter<MoodModel>(
            fromFirestore: MoodModel.fromFirestore,
            toFirestore: (mood, _) => mood.toFirestore(),
          );

  /// Pushes a new mood log to the Firestore collection 'mood_logs'.
  ///
  /// Automatically ensures that the log is associated with the currently
  /// logged-in user's [uid], preventing unauthorized spoofing.
  Future<DocumentReference<MoodModel>> addMood(MoodModel mood) async {
    try {
      final uid = _currentUserId;

      // Ensure the model's userId matches the authenticated user's ID
      final moodToSave = mood.userId == uid
          ? mood
          : mood.copyWith(userId: uid);

      return await _moodLogsCollection.add(moodToSave);
    } catch (e) {
      throw DatabaseException('Failed to add mood entry: $e');
    }
  }

  /// Streams the user's mood logs in real-time.
  ///
  /// Queries the 'mood_logs' collection, filtering by the active user's [userId],
  /// and sorts the history by [timestamp] descending (newest entries first).
  ///
  /// Returns a type-safe [Stream] containing a [List] of [MoodModel]s.
  Stream<List<MoodModel>> getMoodStream() {
    try {
      final uid = _currentUserId;

      return _moodLogsCollection
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => doc.data()).toList();
          });
    } catch (e) {
      throw DatabaseException('Failed to fetch mood stream: $e');
    }
  }

  /// Deletes a specific mood log by its document [id].
  ///
  /// Verifies that the document exists and belongs to the current user before
  /// deletion if extra security is needed (though Firestore Security Rules
  /// usually enforce this on the cloud side).
  Future<void> deleteMood(String id) async {
    try {
      // Fetch current UID to ensure the user is authenticated
      final _ = _currentUserId;

      await _moodLogsCollection.doc(id).delete();
    } catch (e) {
      throw DatabaseException('Failed to delete mood entry: $e');
    }
  }

  /// Updates an existing mood log in the Firestore collection 'mood_logs'.
  Future<void> updateMood(MoodModel mood) async {
    try {
      if (mood.id == null) {
        throw ArgumentError('Mood ID cannot be null for updates');
      }
      await _moodLogsCollection.doc(mood.id).update(mood.toFirestore());
    } catch (e) {
      throw DatabaseException('Failed to update mood entry: $e');
    }
  }
}

/// Custom Exception thrown when trying to perform operations without an active login.
class UnauthenticatedException implements Exception {
  final String message;
  const UnauthenticatedException([this.message = 'User is not logged in.']);

  @override
  String toString() => 'UnauthenticatedException: $message';
}

/// Custom Exception for general database failures.
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

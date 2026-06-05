import 'package:cloud_firestore/cloud_firestore.dart';

/// A data model representing a user's logged mood entry.
/// Follows Clean Architecture and is optimized for Firebase Firestore.
class MoodModel {
  /// The unique document ID from Firestore (nullable if not yet saved)
  final String? id;

  /// The unique identifier of the user who logged this mood
  final String userId;

  /// The mood score, strictly between 1 (Very Sad/Low) and 5 (Very Happy/Excellent)
  final int moodScore;

  /// Optional personal note or reflection about the mood entry
  final String? note;

  /// List of tag strings representing feelings or activities (e.g., ['happy', 'productive'])
  final List<String> tags;

  /// The date and time when this mood was logged
  final DateTime timestamp;

  /// Offline calculated sentiment score, ranging from -5.0 (extremely negative) to 5.0 (extremely positive)
  final double? sentimentScore;

  /// Main constructor with business rule assertion for moodScore
  MoodModel({
    this.id,
    required this.userId,
    required this.moodScore,
    this.note,
    required this.tags,
    required this.timestamp,
    this.sentimentScore,
  }) : assert(
          moodScore >= 1 && moodScore <= 5,
          'Mood score must be an integer between 1 and 5 inclusive.',
        );

  /// Creates a copy of the current [MoodModel] with updated fields.
  /// Extremely useful for state-management solutions like Bloc, Riverpod, or Provider.
  MoodModel copyWith({
    String? id,
    String? userId,
    int? moodScore,
    String? note,
    List<String>? tags,
    DateTime? timestamp,
    double? sentimentScore,
  }) {
    return MoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodScore: moodScore ?? this.moodScore,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      sentimentScore: sentimentScore ?? this.sentimentScore,
    );
  }

  /// Converts a Firestore [DocumentSnapshot] into a type-safe [MoodModel].
  ///
  /// This signature matches the Firestore generic converter interface perfectly:
  /// `fromFirestore: (snapshot, options) => MoodModel.fromFirestore(snapshot, options)`
  factory MoodModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw ArgumentError("Document data was null for ID: ${snapshot.id}");
    }

    // Safely parse the tags list. Converts List<dynamic> to List<String>.
    final List<String> parsedTags = data['tags'] != null
        ? List<String>.from(data['tags'] as Iterable)
        : <String>[];

    // Safely parse Firestore Timestamp. Supports standard Firestore Timestamp,
    // ISO string, or milliseconds epoch for complete backward/forward compatibility.
    final rawTimestamp = data['timestamp'];
    DateTime parsedTimestamp = DateTime.now();
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    }

    return MoodModel(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      moodScore: (data['moodScore'] as num? ?? 3).toInt(),
      note: data['note'] as String?,
      tags: parsedTags,
      timestamp: parsedTimestamp,
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble(),
    );
  }

  /// Converts this [MoodModel] to a [Map<String, dynamic>] format suitable for storing in Firestore.
  ///
  /// This signature matches the Firestore generic converter interface:
  /// `toFirestore: (mood, options) => mood.toFirestore()`
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'moodScore': moodScore,
      if (note != null) 'note': note,
      'tags': tags,
      'timestamp': Timestamp.fromDate(timestamp), // Firestore Native Timestamp
      if (sentimentScore != null) 'sentimentScore': sentimentScore,
    };
  }

  /// Helper factory to create a [MoodModel] from a standard Map.
  /// Useful for testing, local database (e.g. SQLite, Hive), or REST API backup.
  factory MoodModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final List<String> parsedTags = map['tags'] != null
        ? List<String>.from(map['tags'] as Iterable)
        : <String>[];

    final rawTimestamp = map['timestamp'];
    DateTime parsedTimestamp = DateTime.now();
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    }

    return MoodModel(
      id: docId ?? map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      moodScore: (map['moodScore'] as num? ?? 3).toInt(),
      note: map['note'] as String?,
      tags: parsedTags,
      timestamp: parsedTimestamp,
      sentimentScore: (map['sentimentScore'] as num?)?.toDouble(),
    );
  }
}

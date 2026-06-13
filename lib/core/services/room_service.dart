import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }
    return user.uid;
  }

  String _generateCode() {
    final r = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(4, (index) => chars[r.nextInt(chars.length)]).join();
    return 'SF-$code';
  }

  /// Creates a new room and returns the generated room code.
  Future<String> createRoom(String roomName, String hostName) async {
    final uid = _currentUserId;
    final roomCode = _generateCode();

    final roomDoc = _firestore.collection('rooms').doc(roomCode);
    await roomDoc.set({
      'id': roomCode,
      'name': roomName,
      'hostId': uid,
      'hostName': hostName,
      'members': [uid],
      'memberNames': {uid: hostName},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Save active room code locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_room_code', roomCode);

    return roomCode;
  }

  /// Joins an existing room using a code.
  Future<void> joinRoom(String roomCode, String memberName) async {
    final uid = _currentUserId;
    final formattedCode = roomCode.trim().toUpperCase();

    final roomDoc = _firestore.collection('rooms').doc(formattedCode);
    final snapshot = await roomDoc.get();

    if (!snapshot.exists) {
      throw Exception('Không tìm thấy phòng với mã này.');
    }

    await _firestore.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(roomDoc);
      final members = List<String>.from(freshSnapshot.get('members') ?? []);
      final memberNames = Map<String, String>.from(freshSnapshot.get('memberNames') ?? {});

      if (!members.contains(uid)) {
        members.add(uid);
      }
      memberNames[uid] = memberName;

      transaction.update(roomDoc, {
        'members': members,
        'memberNames': memberNames,
      });
    });

    // Save active room code locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_room_code', formattedCode);
  }

  /// Sends a text message or a shared achievement certificate.
  Future<void> sendMessage(String roomCode, String text, {Map<String, dynamic>? achievementData}) async {
    final uid = _currentUserId;
    
    // Fetch sender name from room document memberNames mapping
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
    String senderName = 'Thành viên';
    if (roomDoc.exists) {
      final memberNames = Map<String, String>.from(roomDoc.get('memberNames') ?? {});
      senderName = memberNames[uid] ?? 'Thành viên';
    }

    await _firestore.collection('rooms').doc(roomCode).collection('messages').add({
      'senderId': uid,
      'senderName': senderName,
      'text': text,
      'type': achievementData != null ? 'achievement' : 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'achievementData': ?achievementData,
    });
  }

  /// Stream to listen for real-time room metadata updates (e.g. member count).
  Stream<DocumentSnapshot<Map<String, dynamic>>> getRoomStream(String roomCode) {
    return _firestore.collection('rooms').doc(roomCode).snapshots();
  }

  /// Stream to listen for real-time messages in a room.
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String roomCode) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Leaves the current room.
  Future<void> leaveRoom(String roomCode) async {
    final uid = _currentUserId;
    final roomDoc = _firestore.collection('rooms').doc(roomCode);

    final snapshot = await roomDoc.get();
    if (snapshot.exists) {
      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(roomDoc);
        final members = List<String>.from(freshSnapshot.get('members') ?? []);
        final memberNames = Map<String, String>.from(freshSnapshot.get('memberNames') ?? {});

        members.remove(uid);
        memberNames.remove(uid);

        transaction.update(roomDoc, {
          'members': members,
          'memberNames': memberNames,
        });
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_room_code');
  }

  /// Retrieves the locally saved active room code.
  Future<String?> getActiveRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_room_code');
  }
}

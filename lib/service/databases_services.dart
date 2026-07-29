import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection('groups');
  final CollectionReference chatroomCollection =
      FirebaseFirestore.instance.collection('chatrooms');
  final CollectionReference friendsCollection =
      FirebaseFirestore.instance.collection('friends');

  // ─────────────────────────────────────────────
  // KULLANICI
  // ─────────────────────────────────────────────

  Future updateUserData(String fullName, String email) async {
    return await userCollection.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'groups': [],
      'profilePic': '',
      'uid': uid,
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final DocumentSnapshot snapshot = await userCollection.doc(uid).get();
    if (!snapshot.exists) return null;
    return snapshot.data() as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final QuerySnapshot snapshot =
        await userCollection.where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data() as Map<String, dynamic>;
  }

  Stream<QuerySnapshot> getUsersStream() {
    return userCollection.snapshots();
  }

  /// Belirli bir kullanıcının anlık verisini dinle (Örn: isOnline, lastSeen)
  Stream<QuerySnapshot> getUserStreamByEmail(String email) {
    return userCollection.where('email', isEqualTo: email).limit(1).snapshots();
  }

  Future<void> updateUserName(String userEmail, String newName) async {
    final snapshot = await userCollection
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.set(
        {'fullName': newName},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> updateUserProfilePic(
      String userEmail, String profilePicUrl) async {
    final QuerySnapshot snapshot = await userCollection
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.set(
        {'profilePic': profilePicUrl},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> setUserOnlineStatus(String email, bool isOnline) async {
    final QuerySnapshot snapshot = await userCollection
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ─────────────────────────────────────────────
  // ARKADAŞLIK SİSTEMİ
  // ─────────────────────────────────────────────

  /// Benzersiz arkadaşlık belgesi ID'si üretir.
  String _friendDocId(String emailA, String emailB) {
    final sorted = [emailA, emailB]..sort();
    return sorted.join('__');
  }

  /// Arkadaşlık isteği gönder (status: 'pending').
  Future<void> sendFriendRequest({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required String toName,
  }) async {
    final docId = _friendDocId(fromEmail, toEmail);
    await friendsCollection.doc(docId).set({
      'users': [fromEmail, toEmail],
      'names': {fromEmail: fromName, toEmail: toName},
      'requestedBy': fromEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Arkadaşlık isteğini kabul et (status: 'accepted').
  Future<void> acceptFriendRequest(String fromEmail, String toEmail) async {
    final docId = _friendDocId(fromEmail, toEmail);
    await friendsCollection.doc(docId).update({'status': 'accepted'});
  }

  /// Arkadaşlık isteğini reddet veya arkadaşlıktan çıkar.
  Future<void> removeFriend(String emailA, String emailB) async {
    final docId = _friendDocId(emailA, emailB);
    await friendsCollection.doc(docId).delete();
  }

  /// Kullanıcının arkadaşlık belgelerini akış olarak dinle.
  Stream<QuerySnapshot> getFriendsStream(String userEmail) {
    return friendsCollection
        .where('users', arrayContains: userEmail)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // DİREKT SOHBET ODASI
  // ─────────────────────────────────────────────

  String buildDirectChatRoomId(String userEmail, String otherUserEmail) {
    final orderedEmails = [userEmail, otherUserEmail]..sort();
    return orderedEmails.join('_');
  }

  Future<String> createOrGetDirectChatRoom({
    required String currentUserEmail,
    required String currentUserName,
    required String otherUserEmail,
    required String otherUserName,
  }) async {
    final String chatRoomId =
        buildDirectChatRoomId(currentUserEmail, otherUserEmail);
    final DocumentReference chatRoomDoc = chatroomCollection.doc(chatRoomId);
    final DocumentSnapshot snapshot = await chatRoomDoc.get();

    if (!snapshot.exists) {
      await chatRoomDoc.set({
        'chatRoomId': chatRoomId,
        'users': [currentUserEmail, otherUserEmail],
        'userNames': [currentUserName, otherUserName],
        'chatRoomName':
            otherUserName.isNotEmpty ? otherUserName : otherUserEmail,
        'lastMessage': '',
        'lastMessageSender': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return chatRoomId;
  }

  Stream<QuerySnapshot> getUserChatRooms(String userEmail) {
    return chatroomCollection
        .where('users', arrayContains: userEmail)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // MESAJLAR (DİREKT)
  // ─────────────────────────────────────────────

  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendChatMessage({
    required String chatRoomId,
    required String senderEmail,
    required String senderName,
    required String message,
    String? fileUrl,
    String? senderProfilePic,
    String? replyToText,
    String? replyToSender,
  }) async {
    final DocumentReference chatRoomDoc = chatroomCollection.doc(chatRoomId);
    await chatRoomDoc.collection('messages').add({
      'senderEmail': senderEmail,
      'senderName': senderName,
      'message': message,
      'fileUrl': fileUrl,
      'senderProfilePic': senderProfilePic,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'readBy': [],
      'reactions': {},
      'edited': false,
    });

    await chatRoomDoc.set({
      'lastMessage': message,
      'lastMessageSender': senderName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteChatMessage(String chatRoomId, String messageId) async {
    await chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> editChatMessage(
      String chatRoomId, String messageId, String newText) async {
    await chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'message': newText, 'edited': true});
  }

  Future<void> markMessageAsRead(
      String chatRoomId, String messageId, String userEmail) async {
    final messageRef = chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);
    await messageRef.update({
      'readBy': FieldValue.arrayUnion([userEmail]),
    });
  }

  Future<void> addMessageReaction(String chatRoomId, String messageId,
      String userEmail, String emoji) async {
    final messageRef = chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);
    await messageRef.update({
      'reactions.$emoji': FieldValue.arrayUnion([userEmail]),
    });
  }

  Future<void> removeMessageReaction(String chatRoomId, String messageId,
      String userEmail, String emoji) async {
    final messageRef = chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);
    await messageRef.update({
      'reactions.$emoji': FieldValue.arrayRemove([userEmail]),
    });
  }

  // ─────────────────────────────────────────────
  // YAZMA DURUMU
  // ─────────────────────────────────────────────

  Future<void> setUserTypingStatus(
      String chatRoomId, String userEmail, bool isTyping) async {
    final DocumentReference typingRef = chatroomCollection
        .doc(chatRoomId)
        .collection('typing')
        .doc(userEmail);
    if (isTyping) {
      await typingRef.set({'timestamp': FieldValue.serverTimestamp()});
    } else {
      await typingRef.delete();
    }
  }

  Stream<QuerySnapshot> getTypingUsers(String chatRoomId) {
    return chatroomCollection
        .doc(chatRoomId)
        .collection('typing')
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // GRUPLAR
  // ─────────────────────────────────────────────

  Stream<QuerySnapshot> getGroupsStream(String userEmail) {
    return groupCollection
        .where('members', arrayContains: userEmail)
        .snapshots();
  }

  Future<String> createGroup({
    required String groupName,
    required String creatorEmail,
    required String creatorName,
  }) async {
    final DocumentReference groupDoc = groupCollection.doc();
    await groupDoc.set({
      'groupId': groupDoc.id,
      'groupName': groupName,
      'creatorEmail': creatorEmail,
      'creatorName': creatorName,
      'members': [creatorEmail],
      'memberNames': {creatorEmail: creatorName},
      'memberCount': 1,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return groupDoc.id;
  }

  Future<void> addMemberToGroup({
    required String groupId,
    required String memberEmail,
    required String memberName,
  }) async {
    await groupCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([memberEmail]),
      'memberNames.$memberEmail': memberName,
      'memberCount': FieldValue.increment(1),
    });
  }

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberEmail,
  }) async {
    await groupCollection.doc(groupId).update({
      'members': FieldValue.arrayRemove([memberEmail]),
      'memberNames.$memberEmail': FieldValue.delete(),
      'memberCount': FieldValue.increment(-1),
    });
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return groupCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String senderEmail,
    required String senderName,
    required String message,
    String? fileUrl,
    String? senderProfilePic,
    String? replyToText,
    String? replyToSender,
  }) async {
    final DocumentReference groupDoc = groupCollection.doc(groupId);
    await groupDoc.collection('messages').add({
      'senderEmail': senderEmail,
      'senderName': senderName,
      'message': message,
      'fileUrl': fileUrl,
      'senderProfilePic': senderProfilePic,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [],
      'reactions': {},
      'edited': false,
    });

    await groupDoc.set({
      'lastMessage': message,
      'lastMessageSender': senderName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    await groupCollection
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> editGroupMessage(
      String groupId, String messageId, String newText) async {
    await groupCollection
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .update({'message': newText, 'edited': true});
  }

  // ─────────────────────────────────────────────
  // MESAJ ARAMA
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchMessages(
      String chatRoomId, String query) async {
    final snapshot = await chatroomCollection
        .doc(chatRoomId)
        .collection('messages')
        .get();
    return snapshot.docs
        .where((doc) => (doc['message'] as String? ?? '')
            .toLowerCase()
            .contains(query.toLowerCase()))
        .map((doc) => doc.data())
        .toList();
  }
}

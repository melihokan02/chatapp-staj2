import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/pages/main_pages/chat_conversation_page.dart';

/// Arka planda gelen mesajları işler (top-level fonksiyon olmalı).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Arka plan bildirimi: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // İzin iste
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Bildirim izni: ${settings.authorizationStatus}');

    // Arka plan handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Uygulama kapalıyken bildirime tıklanırsa
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    // Uygulama arka plandayken (ama açıkken) bildirime tıklanırsa
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Ön plan mesajı
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Ön plan bildirimi: ${message.notification?.title}');
    });
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['chatId'] != null) {
      final chatId = message.data['chatId'];
      final isGroupChat = message.data['isGroupChat'] == 'true';
      final title = message.data['title'] ?? 'Sohbet';
      final subtitle = message.data['subtitle'] ?? '';
      final avatarLabel = message.data['avatarLabel'] ?? 'S';

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatConversationPage(
            chatId: chatId,
            title: title,
            subtitle: subtitle,
            avatarLabel: avatarLabel,
            isGroupChat: isGroupChat,
          ),
        ),
      );
    }
  }

  /// Kullanıcının FCM token'ını Firestore'a kaydeder.
  Future<void> saveFcmToken(String userEmail) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.set(
            {'fcmToken': token},
            SetOptions(merge: true),
          );
        }
      });
      debugPrint('FCM token kaydedildi');
    } catch (e) {
      debugPrint('FCM token kayıt hatası: $e');
    }
  }

  /// Token yenilendiğinde günceller.
  void listenTokenRefresh(String userEmail) {
    _messaging.onTokenRefresh.listen((newToken) async {
      await saveFcmToken(userEmail);
    });
  }

  /// Çıkış yaparken FCM token'ı siler.
  Future<void> clearFcmToken(String userEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'fcmToken': FieldValue.delete(),
          });
        }
      });
      debugPrint('FCM token silindi');
    } catch (e) {
      debugPrint('FCM token silme hatası: $e');
    }
  }
}

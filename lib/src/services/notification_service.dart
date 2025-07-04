import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService(this.navigatorKey);
  initFCM() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
    } else {
      print('Failed to get FCM token');
    }

    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print(
        'Initial message: ${initialMessage.notification?.title} - ${initialMessage.notification?.body}',
      );
      // Aquí puedes manejar la notificación inicial si la aplicación se abrió desde una notificación
      // navigatorKey.currentState?.pushNamed(
      //   '/notification',
      //   arguments: initialMessage,
      // );
    }
    print('==== FCM Initialized ====');

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        'Received message: ${message.notification?.title} - ${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
        'Foreground message: ${message.notification?.title} - ${message.notification?.body}',
      );
      print('Data: ${message.data}');
      setRaza(message.data['raza'] ?? 'Unknown');
    });

  }

  Future<AccessCredentials> _getAccessToken() async {
    final serviceAccountPath = dotenv.env['PATH_TO_SECRET'];

    String serviceAccountJson = await rootBundle.loadString(
      serviceAccountPath!,
    );

    // log("json: $serviceAccountJson");
    final serviceAccount = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(serviceAccount, scopes);
    return client.credentials;
  }

  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (deviceToken.isEmpty) return false;

    final credentials = await _getAccessToken();
    final accessToken = credentials.accessToken.data;
    final projectId = dotenv.env['PROJECT_ID'];

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully.');
      return true;
    } else {
      print('Failed to send notification: ${response.body}');
      return false;
    }
  }
  void setRaza(String raza) {
    print('Raza recibida: $raza');
    // navigatorKey.currentState?.pushNamed('/raza', arguments: raza);
  }
}

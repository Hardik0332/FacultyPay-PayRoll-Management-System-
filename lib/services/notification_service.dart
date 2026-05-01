import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ Added for debugPrint
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  final String _projectId = 'facultypay';

  // --- INTERNAL LOGIC TO TALK TO GOOGLE ---

  Future<String> _getAccessToken() async {
    // 1. Fetch the secret from the .env file
    String serviceAccountJson = dotenv.env['GOOGLE_SERVICE_ACCOUNT_KEY'] ?? '';

    // Strip away any accidental single quotes or extra spaces
    serviceAccountJson = serviceAccountJson.trim();
    if (serviceAccountJson.startsWith("'") && serviceAccountJson.endsWith("'")) {
      serviceAccountJson = serviceAccountJson.substring(1, serviceAccountJson.length - 1);
    }

    // 2. Validate that it actually exists
    if (serviceAccountJson.isEmpty) {
      debugPrint("❌ WARNING: Service account key is missing from .env file!");
      throw Exception("Missing GOOGLE_SERVICE_ACCOUNT_KEY in .env");
    }

    // 3. Authenticate with Google
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final authClient = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final token = authClient.credentials.accessToken.data;

    authClient.close();
    return token;
  }

  Future<void> _sendPushMessage(String fcmToken, String title, String body) async {
    try {
      final String accessToken = await _getAccessToken();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final Map<String, dynamic> message = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            // ✅ Priority goes here, NOT inside notification
            "priority": "high",
            "notification": {
              "channel_id": "high_importance_channel",
              "visibility": "public"
            }
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          }
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Push Notification Sent Successfully!');
      } else {
        debugPrint('❌ Failed to send push notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
    }
  }

  Future<String?> _getUserToken(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['fcmToken'];
    }
    return null;
  }

  // ====================================================================
  // ✅ IN-APP DATABASE SAVING LOGIC
  // ====================================================================

  Future<void> _saveToDatabase(String uid, String title, String body) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': uid,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      debugPrint('✅ Notification saved to database for in-app viewing.');
    } catch (e) {
      debugPrint('❌ Error saving notification to database: $e');
    }
  }


  // ====================================================================
  // THESE ARE THE METHODS YOUR ADMIN APP CALLS
  // ====================================================================

  Future<void> sendLogApprovedNotification({required String uid, required int count, required String subject}) async {
    String title = "Log Approved! ✅";
    String body = "Your $count lecture(s) for $subject have been verified by the Admin.";

    // 1. Save to Database (Triggers In-App Red Dot)
    await _saveToDatabase(uid, title, body);

    // 2. Send Push Notification (Triggers Phone Buzz)
    String? fcmToken = await _getUserToken(uid);
    if (fcmToken != null) {
      await _sendPushMessage(fcmToken, title, body);
    }
  }

  Future<void> sendLogRejectedNotification({required String uid, required String subject}) async {
    String title = "Log Rejected ❌";
    String body = "Your log for $subject was rejected. Please check your dashboard for details.";

    await _saveToDatabase(uid, title, body);

    String? fcmToken = await _getUserToken(uid);
    if (fcmToken != null) {
      await _sendPushMessage(fcmToken, title, body);
    }
  }

  Future<void> sendPaymentProcessedNotification({required String uid, required double amount}) async {
    String title = "Payment Processed! 💰";
    String body = "₹${amount.toStringAsFixed(2)} has been cleared and sent to your account.";

    await _saveToDatabase(uid, title, body);

    String? fcmToken = await _getUserToken(uid);
    if (fcmToken != null) {
      await _sendPushMessage(fcmToken, title, body);
    }
  }
}
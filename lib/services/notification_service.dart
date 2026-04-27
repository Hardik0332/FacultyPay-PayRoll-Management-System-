import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendLogApprovedNotification({
    required String uid,
    required int count,
    required String subject,
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'title': 'Logs Approved',
      'message': 'Your $count lectures for $subject have been verified by the Admin.',
      'type': 'success',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendLogRejectedNotification({
    required String uid,
    required String subject,
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'title': 'Log Rejected',
      'message': 'Your log for $subject was rejected. Please review your submission.',
      'type': 'error',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPaymentProcessedNotification({
    required String uid,
    required double amount,
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'title': 'Payment Processed',
      'message': 'Payment of ₹${amount.toStringAsFixed(2)} has been processed. Your payslip is ready to download.',
      'type': 'success',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendProfileUpdateNotification({
    required String uid,
    String? message,
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'title': 'Profile/Security Update',
      'message': message ?? 'Your UPI ID was successfully updated.',
      'type': 'info',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendSystemReminder({
    required String uid,
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'title': 'System Reminder',
      'message': "Month-End Reminder: Don't forget to log all your remaining hours for this month!",
      'type': 'warning',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String uid) async {
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

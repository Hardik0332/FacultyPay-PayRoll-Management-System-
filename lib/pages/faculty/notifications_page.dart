import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Color primaryRed = const Color(0xFFE05B5C);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _markAllRead() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking all read: $e");
    }
  }

  Future<void> _deleteNotification(String id) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282C37),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text("Mark all read", style: TextStyle(color: primaryRed, fontSize: 12)),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B4154), Color(0xFF1E212A)],
              ),
            ),
          ),

          // Firebase Data Stream
          currentUser == null
              ? const Center(child: Text("Please login to view notifications", style: TextStyle(color: Colors.white)))
              : StreamBuilder<QuerySnapshot>(
            // ✅ REMOVED the .orderBy() to prevent the Firebase Index Error
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid', isEqualTo: currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryRed));
              }

              if (snapshot.hasError) {
                debugPrint("Notification Error: ${snapshot.error}");
                return Center(child: Text("Error fetching notifications", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No notifications", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                );
              }

              // ✅ ADDED Local sorting in Dart
              List<QueryDocumentSnapshot> allDocs = snapshot.data!.docs.toList();
              allDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                Timestamp? aTime = aData['createdAt'] as Timestamp?;
                Timestamp? bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime); // Sorts newest first
              });

              // Separate notifications into sections
              List<QueryDocumentSnapshot> todayNotifs = [];
              List<QueryDocumentSnapshot> olderNotifs = [];

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);

              for (var doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt = data['createdAt'] as Timestamp?;
                if (createdAt != null) {
                  final date = createdAt.toDate();
                  if (date.isAfter(todayStart)) {
                    todayNotifs.add(doc);
                  } else {
                    olderNotifs.add(doc);
                  }
                } else {
                  olderNotifs.add(doc);
                }
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (todayNotifs.isNotEmpty) ...[
                    const Text("TODAY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ...todayNotifs.map((doc) => _buildNotificationItem(doc)).toList(),
                    const SizedBox(height: 24),
                  ],
                  if (olderNotifs.isNotEmpty) ...[
                    const Text("OLDER", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ...olderNotifs.map((doc) => _buildNotificationItem(doc)).toList(),
                  ],
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? 'info';
    final isUnread = !isRead;

    // Default time formatting
    String timeStr = "";
    if (data['createdAt'] != null) {
      final date = (data['createdAt'] as Timestamp).toDate();
      timeStr = DateFormat('hh:mm a, MMM dd').format(date);
    }

    // Determine colors and icons based on type
    Color iconColor = Colors.grey;
    IconData icon = Icons.notifications;

    switch (type) {
      case 'success':
        iconColor = const Color(0xFF4ADE80);
        icon = Icons.check_circle;
        break;
      case 'error':
        iconColor = const Color(0xFFE05B5C);
        icon = Icons.error;
        break;
      case 'info':
        iconColor = const Color(0xFF60A5FA);
        icon = Icons.info;
        break;
      case 'warning':
        iconColor = const Color(0xFFFBBF24);
        icon = Icons.warning_amber_rounded;
        break;
      default:
        iconColor = primaryRed;
        icon = Icons.notifications;
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF2A2E39),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isUnread ? iconColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(timeStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(message, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFE05B5C), shape: BoxShape.circle),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
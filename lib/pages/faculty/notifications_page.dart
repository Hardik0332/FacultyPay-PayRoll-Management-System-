import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../theme/theme_manager.dart'; // ✅ Added ThemeManager

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // AUTO-CLEAR RED DOT
    Future.delayed(const Duration(seconds: 1), () {
      _markAllRead();
    });
  }

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
    return AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final colors = ThemeManager.instance.colors;
          final isDark = ThemeManager.instance.isDarkMode;

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: colors.bgBottom, // ✅ DYNAMIC
                body: Stack(
                  children: [
                    // Background Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colors.bgTop, colors.bgBottom], // ✅ DYNAMIC
                        ),
                      ),
                    ),

                    // Main Content
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Custom Inline Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back_ios_new, color: colors.textMain, size: 20),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Text("Notifications", style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold, fontSize: 18)),
                                    TextButton(
                                      onPressed: _markAllRead,
                                      child: Text("Mark all read", style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),

                              // The Notification List
                              Expanded(
                                child: currentUser == null
                                    ? Center(child: Text("Please login to view notifications", style: TextStyle(color: colors.textMuted)))
                                    : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('notifications')
                                      .where('uid', isEqualTo: currentUser!.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator(color: colors.primary));
                                    }

                                    if (snapshot.hasError) {
                                      return Center(child: Text("Error fetching notifications", style: TextStyle(color: colors.textMuted)));
                                    }

                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return Center(
                                        child: Text("No notifications", style: TextStyle(color: colors.textMuted)),
                                      );
                                    }

                                    List<QueryDocumentSnapshot> allDocs = snapshot.data!.docs.toList();

                                    allDocs.sort((a, b) {
                                      final aData = a.data() as Map<String, dynamic>;
                                      final bData = b.data() as Map<String, dynamic>;
                                      Timestamp? aTime = aData['timestamp'] as Timestamp?;
                                      Timestamp? bTime = bData['timestamp'] as Timestamp?;
                                      if (aTime == null || bTime == null) return 0;
                                      return bTime.compareTo(aTime);
                                    });

                                    List<QueryDocumentSnapshot> todayNotifs = [];
                                    List<QueryDocumentSnapshot> olderNotifs = [];

                                    final now = DateTime.now();
                                    final todayStart = DateTime(now.year, now.month, now.day);

                                    for (var doc in allDocs) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final createdAt = data['timestamp'] as Timestamp?;
                                      if (createdAt != null) {
                                        final date = createdAt.toDate().toLocal();
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      physics: const BouncingScrollPhysics(),
                                      children: [
                                        if (todayNotifs.isNotEmpty) ...[
                                          Text("TODAY", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          const SizedBox(height: 12),
                                          ...todayNotifs.map((doc) => _buildNotificationItem(doc, colors, isDark)).toList(),
                                          const SizedBox(height: 24),
                                        ],
                                        if (olderNotifs.isNotEmpty) ...[
                                          Text("OLDER", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          const SizedBox(height: 12),
                                          ...olderNotifs.map((doc) => _buildNotificationItem(doc, colors, isDark)).toList(),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot doc, AppColors colors, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final title = data['title'] ?? 'Notification';
    final message = data['body'] ?? '';
    final isRead = data['isRead'] ?? false;
    final isUnread = !isRead;

    String type = data['type'] ?? 'info';
    if (data['type'] == null) {
      if (title.toLowerCase().contains('approved') || title.toLowerCase().contains('processed')) {
        type = 'success';
      } else if (title.toLowerCase().contains('rejected')) {
        type = 'error';
      }
    }

    String timeStr = "";
    if (data['timestamp'] != null) {
      final date = (data['timestamp'] as Timestamp).toDate().toLocal();
      timeStr = DateFormat('hh:mm a, MMM dd').format(date);
    }

    Color iconColor = colors.textMuted;
    IconData icon = Icons.notifications;

    // ✅ Map notification types to Theme Colors
    switch (type) {
      case 'success':
        iconColor = colors.success;
        icon = Icons.check_circle;
        break;
      case 'error':
        iconColor = colors.error;
        icon = Icons.error;
        break;
      case 'info':
        iconColor = colors.processing;
        icon = Icons.info;
        break;
      case 'warning':
        iconColor = colors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        iconColor = colors.primary;
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
          color: colors.error.withValues(alpha: 0.8), // Standard Red for delete
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
            // Unread notifications get a subtle tint of their icon color
            color: isUnread
                ? (isDark ? colors.textMain.withValues(alpha: 0.05) : iconColor.withValues(alpha: 0.05))
                : colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isUnread ? iconColor.withValues(alpha: 0.3) : (isDark ? colors.textMain.withValues(alpha: 0.05) : Colors.transparent)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                          child: Text(title, style: TextStyle(color: colors.textMain, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(timeStr, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(message, style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: colors.error, shape: BoxShape.circle), // Red dot for unread status
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
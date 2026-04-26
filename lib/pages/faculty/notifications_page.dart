import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE05B5C);

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
            onPressed: () {}, // Logic to mark all as read
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

          // Notifications List
          ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              const Text("TODAY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF4ADE80), // Success Green
                title: "Payment Processed",
                message: "₹40,500.00 for February 2026 has been credited to your UPI.",
                time: "10:30 AM",
                isUnread: true,
              ),
              _buildNotificationItem(
                icon: Icons.verified,
                iconColor: const Color(0xFF60A5FA), // Verified Blue
                title: "Logs Approved",
                message: "Your 2 lectures for 'Cloud Computing' have been verified.",
                time: "09:15 AM",
                isUnread: true,
              ),

              const SizedBox(height: 24),
              const Text("THIS WEEK", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              _buildNotificationItem(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFBBF24), // Pending Orange
                title: "Action Required",
                message: "Please double-check your custom subject entry for Apr 22.",
                time: "Mon",
                isUnread: false,
              ),
              _buildNotificationItem(
                icon: Icons.event_note,
                iconColor: primaryRed,
                title: "Month-End Reminder",
                message: "Don't forget to log all your April hours by the 30th!",
                time: "Sun",
                isUnread: false,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread
  }) {
    return Padding(
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
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
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
    );
  }
}
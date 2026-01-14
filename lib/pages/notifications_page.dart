import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale değiştiğinde bildirimleri yeniden yükle
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Görev istatistiklerini al
    final user = FirebaseAuth.instance.currentUser;
    int completed = 0;
    int total = 0;

    if (user != null) {
      final tasksRef = FirebaseFirestore.instance.collection('tasks');
      final snapshot =
          await tasksRef.where('userId', isEqualTo: user.uid).get();
      completed = snapshot.docs.where((doc) => doc['completed'] == true).length;
      total = snapshot.docs.length;
    }

    final rate = total == 0 ? 0 : (completed / total * 100).toInt();

    // Bildirimleri oluştur
    final now = DateTime.now();
    final notifications = <NotificationItem>[];

    // Sabah bildirimi (09:00)
    notifications.add(
      NotificationItem(
        id: 'morning',
        titleKey: 'morningTitle',
        bodyKey: _getMorningMessageKey(),
        time: DateTime(now.year, now.month, now.day, 9, 0),
        type: NotificationType.morning,
        isScheduled: now.hour < 9,
      ),
    );

    // Öğle bildirimi (13:00)
    notifications.add(
      NotificationItem(
        id: 'afternoon',
        titleKey: 'afternoonTitle',
        bodyKey: _getAfternoonMessageKey(),
        time: DateTime(now.year, now.month, now.day, 13, 0),
        type: NotificationType.afternoon,
        isScheduled: now.hour < 13,
      ),
    );

    // Akşam bildirimi (20:00)
    notifications.add(
      NotificationItem(
        id: 'evening',
        titleKey: 'eveningTitle',
        bodyKey: _getEveningMessageKey(rate, completed, total),
        bodyArgs: {
          'rate': rate.toString(),
          'completed': completed.toString(),
          'total': total.toString(),
        },
        time: DateTime(now.year, now.month, now.day, 20, 0),
        type: NotificationType.evening,
        isScheduled: now.hour < 20,
      ),
    );

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  String _getMorningMessageKey() {
    final messages = ['morningMsg1', 'morningMsg2', 'morningMsg3'];
    return messages[DateTime.now().day % messages.length];
  }

  String _getAfternoonMessageKey() {
    final messages = ['afternoonMsg1', 'afternoonMsg2', 'afternoonMsg3'];
    return messages[DateTime.now().day % messages.length];
  }

  String _getEveningMessageKey(int rate, int completed, int total) {
    if (total == 0) {
      return 'eveningMsgNoTasks';
    }

    if (rate == 100) {
      return 'eveningMsgPerfect';
    } else if (rate >= 75) {
      return 'eveningMsgGreat';
    } else if (rate >= 50) {
      return 'eveningMsgGood';
    } else {
      return 'eveningMsgStart';
    }
  }

  Future<void> _sendNotificationNow(NotificationItem item) async {
    // Telefona bildirim gönder
    switch (item.type) {
      case NotificationType.morning:
        await NotifyService.testMorningNotification();
        break;
      case NotificationType.afternoon:
        await NotifyService.testAfternoonNotification();
        break;
      case NotificationType.evening:
        await NotifyService.testEveningNotification();
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notificationSent'.tr()),
          backgroundColor: const Color(0xFF06A77D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'notificationsTitle'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
                )
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Bildirim zamanları bilgisi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFF00B4D8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'notificationsInfo'.tr(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bildirim listesi
                    ..._notifications.map(
                      (item) => _buildNotificationCard(item),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final now = DateTime.now();
    final isPast = now.hour >= item.time.hour;
    final statusText =
        isPast
            ? 'notificationSentStatus'.tr()
            : 'notificationScheduledStatus'.tr();

    Color accentColor;
    switch (item.type) {
      case NotificationType.morning:
        accentColor = const Color(0xFFFFB347);
        break;
      case NotificationType.afternoon:
        accentColor = const Color(0xFFE94560);
        break;
      case NotificationType.evening:
        accentColor = const Color(0xFF00B4D8);
        break;
    }

    // Body text with args if available
    String bodyText;
    if (item.bodyArgs != null) {
      bodyText = item.bodyKey.tr(namedArgs: item.bodyArgs!);
    } else {
      bodyText = item.bodyKey.tr();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendNotificationNow(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPast
                                ? const Color(0xFF06A77D).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPast ? Icons.check_circle : Icons.schedule,
                            size: 14,
                            color:
                                isPast
                                    ? const Color(0xFF06A77D)
                                    : Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isPast
                                      ? const Color(0xFF06A77D)
                                      : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.titleKey.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bodyText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'notificationTapToSend'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum NotificationType { morning, afternoon, evening }

class NotificationItem {
  final String id;
  final String titleKey;
  final String bodyKey;
  final Map<String, String>? bodyArgs;
  final DateTime time;
  final NotificationType type;
  final bool isScheduled;

  NotificationItem({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    this.bodyArgs,
    required this.time,
    required this.type,
    required this.isScheduled,
  });
}

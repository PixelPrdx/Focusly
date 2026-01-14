import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotifyService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Motivasyon mesajları - Türkçe
  static const List<String> _morningMotivationsTr = [
    "🌅 Günaydın! Bugün harika işler başarabilirsin!",
    "☀️ Yeni bir gün, yeni fırsatlar! Haydi başlayalım!",
    "🎯 Bugün hedeflerine bir adım daha yaklaş!",
    "💪 Her yeni gün bir şans! Bunu değerlendir!",
    "🚀 Bugün senin günün! Harika şeyler seni bekliyor!",
  ];

  static const List<String> _afternoonMotivationsTr = [
    "🔥 Öğle molası bitti, devam edelim!",
    "💪 Yarısını tamamladın, geri kalanı da halledeceğiz!",
    "🎯 Odaklan ve devam et, başarı yakın!",
    "⚡ Enerjini yenile ve hedeflerine doğru ilerle!",
    "🌟 İyi gidiyorsun! Devam et!",
  ];

  // Motivasyon mesajları - İngilizce
  static const List<String> _morningMotivationsEn = [
    "🌅 Good morning! You can accomplish great things today!",
    "☀️ New day, new opportunities! Let's get started!",
    "🎯 Get one step closer to your goals today!",
    "💪 Every new day is a chance! Make the most of it!",
    "🚀 Today is your day! Great things are waiting for you!",
  ];

  static const List<String> _afternoonMotivationsEn = [
    "🔥 Lunch break is over, let's continue!",
    "💪 You've completed half, we'll handle the rest!",
    "🎯 Stay focused and keep going, success is near!",
    "⚡ Refresh your energy and move towards your goals!",
    "🌟 You're doing great! Keep it up!",
  ];

  // Görev oranına göre mesajlar - Türkçe
  static const Map<String, String> _taskMotivationsTr = {
    'perfect': "🌟 Mükemmel! Bugün tüm görevlerini tamamladın! Gurur duy!",
    'great': "🎯 Harika iş çıkardın! Neredeyse tamamladın! %{rate} tamamlandı!",
    'good': "📈 İyi ilerliyorsun! %{rate} tamamlandı. Devam et!",
    'start': "💪 Her adım önemli! %{rate} tamamladın. Yarın daha iyi olacak!",
    'ready': "✨ Bugün görev eklemeye başla! Yeni hedefler seni bekliyor!",
  };

  // Görev oranına göre mesajlar - İngilizce
  static const Map<String, String> _taskMotivationsEn = {
    'perfect': "🌟 Perfect! You completed all tasks today! Be proud!",
    'great': "🎯 Great job! Almost done! %{rate} completed!",
    'good': "📈 You're making progress! %{rate} completed. Keep going!",
    'start':
        "💪 Every step counts! %{rate} completed. Tomorrow will be better!",
    'ready': "✨ Start adding tasks today! New goals await you!",
  };

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Timezone başlat
      tz_data.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Timezone alınamazsa varsayılan kullan
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(settings);
      _initialized = true;

      // Günlük bildirimleri planla
      try {
        await scheduleDailyMotivations();
      } catch (e) {
        // Bildirim zamanlama hatası - kritik değil
        debugPrint('Bildirim zamanlama hatası: $e');
      }
    } catch (e) {
      debugPrint('NotifyService init hatası: $e');
    }
  }

  // Pomodoro tamamlandığında bildirim
  static Future<void> showDone() async {
    const android = AndroidNotificationDetails(
      'pomodoro',
      'Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.show(
      0,
      "Pomodoro Finished!",
      "Time for a break ☕",
      const NotificationDetails(android: android, iOS: ios),
    );
  }

  // Günlük motivasyon bildirimlerini planla
  static Future<void> scheduleDailyMotivations() async {
    // Önceki bildirimleri iptal et
    await _plugin.cancelAll();

    // Dili kontrol et
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'en';

    // Sabah 09:00 bildirimi
    await _scheduleDaily(
      id: 100,
      hour: 9,
      minute: 0,
      title: lang == 'tr' ? 'Günaydın! 🌅' : 'Good Morning! 🌅',
      body: _getRandomMotivation(lang, 'morning'),
    );

    // Öğle 13:00 bildirimi
    await _scheduleDaily(
      id: 101,
      hour: 13,
      minute: 0,
      title: lang == 'tr' ? 'Öğle Motivasyonu 🔥' : 'Afternoon Motivation 🔥',
      body: _getRandomMotivation(lang, 'afternoon'),
    );

    // Akşam 20:00 bildirimi - görev oranına göre
    await _scheduleEveningMotivation(lang);
  }

  // Akşam bildirimini görev oranına göre planla
  static Future<void> _scheduleEveningMotivation(String lang) async {
    await _scheduleDaily(
      id: 102,
      hour: 20,
      minute: 0,
      title: lang == 'tr' ? 'Günün Özeti 📊' : 'Daily Summary 📊',
      body:
          lang == 'tr'
              ? 'Bugünkü performansını görmek için uygulamayı aç!'
              : 'Open the app to see your today\'s performance!',
    );
  }

  // Günlük zamanlanmış bildirim
  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Eğer zaman geçmişse, yarına planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const android = AndroidNotificationDetails(
      'motivation',
      'Motivasyon Bildirimleri',
      channelDescription: 'Günlük motivasyon bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Rastgele motivasyon mesajı seç
  static String _getRandomMotivation(String lang, String type) {
    final random = DateTime.now().millisecondsSinceEpoch % 5;

    if (type == 'morning') {
      return lang == 'tr'
          ? _morningMotivationsTr[random]
          : _morningMotivationsEn[random];
    } else {
      return lang == 'tr'
          ? _afternoonMotivationsTr[random]
          : _afternoonMotivationsEn[random];
    }
  }

  // Görev tamamlama oranına göre bildirim gönder
  static Future<void> sendTaskCompletionNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'en';

    // Görev istatistiklerini al
    final tasksRef = FirebaseFirestore.instance.collection('tasks');
    final snapshot = await tasksRef.where('userId', isEqualTo: user.uid).get();

    final completed =
        snapshot.docs.where((doc) => doc['completed'] == true).length;
    final total = snapshot.docs.length;

    String message;
    String title =
        lang == 'tr' ? 'Günlük Performans 📊' : 'Daily Performance 📊';

    if (total == 0) {
      message =
          lang == 'tr'
              ? _taskMotivationsTr['ready']!
              : _taskMotivationsEn['ready']!;
    } else {
      final rate = (completed / total * 100).toInt();
      final rateStr = '$rate%';

      if (rate == 100) {
        message =
            lang == 'tr'
                ? _taskMotivationsTr['perfect']!
                : _taskMotivationsEn['perfect']!;
      } else if (rate >= 75) {
        message = (lang == 'tr'
                ? _taskMotivationsTr['great']!
                : _taskMotivationsEn['great']!)
            .replaceAll('%{rate}', rateStr);
      } else if (rate >= 50) {
        message = (lang == 'tr'
                ? _taskMotivationsTr['good']!
                : _taskMotivationsEn['good']!)
            .replaceAll('%{rate}', rateStr);
      } else {
        message = (lang == 'tr'
                ? _taskMotivationsTr['start']!
                : _taskMotivationsEn['start']!)
            .replaceAll('%{rate}', rateStr);
      }
    }

    const android = AndroidNotificationDetails(
      'task_motivation',
      'Görev Motivasyonu',
      channelDescription: 'Görev tamamlama oranına göre motivasyon',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.show(
      200,
      title,
      message,
      const NotificationDetails(android: android, iOS: ios),
    );
  }

  // Dil değiştiğinde bildirimleri yeniden planla
  static Future<void> rescheduleOnLanguageChange() async {
    await scheduleDailyMotivations();
  }

  // ============ TEST METODLARI ============

  /// Sabah bildirimini hemen test et
  static Future<void> testMorningNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'en';

    const android = AndroidNotificationDetails(
      'motivation_test',
      'Test Bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.show(
      300,
      lang == 'tr' ? '🌅 Günaydın! (TEST)' : '🌅 Good Morning! (TEST)',
      _getRandomMotivation(lang, 'morning'),
      const NotificationDetails(android: android, iOS: ios),
    );
  }

  /// Öğle bildirimini hemen test et
  static Future<void> testAfternoonNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'en';

    const android = AndroidNotificationDetails(
      'motivation_test',
      'Test Bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.show(
      301,
      lang == 'tr'
          ? '🔥 Öğle Motivasyonu (TEST)'
          : '🔥 Afternoon Motivation (TEST)',
      _getRandomMotivation(lang, 'afternoon'),
      const NotificationDetails(android: android, iOS: ios),
    );
  }

  /// Akşam/görev bildirimini hemen test et
  static Future<void> testEveningNotification() async {
    await sendTaskCompletionNotification();
  }

  /// Tüm bildirimleri sırayla test et (3 saniye arayla)
  static Future<void> testAllNotifications() async {
    await testMorningNotification();
    await Future.delayed(const Duration(seconds: 3));
    await testAfternoonNotification();
    await Future.delayed(const Duration(seconds: 3));
    await testEveningNotification();
  }
}

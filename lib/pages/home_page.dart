import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'pomodoro_page.dart';
import 'todo_page.dart';

import 'analytics_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'notifications_page.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _sessionDuration = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _streakDays = 0;
  late SharedPreferences _prefs;
  late Timer _durationTimer;
  late String userId;
  late TabController _tabController;
  final AuthService _authService = AuthService();
  StreamSubscription<QuerySnapshot>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    _initializeData();
    _startDurationTimer();
    _setupTaskListener();
  }

  Future<void> _initializeData() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSessionDuration();
    _loadStreakDays();
    _loadTaskStats();
  }

  void _loadSessionDuration() {
    final savedTime = _prefs.getInt('session_duration_today') ?? 0;
    final lastDate = _prefs.getString('last_session_date') ?? '';
    final today = DateTime.now().toString().split(' ')[0];

    if (lastDate != today) {
      // Yeni gün başladı, sürü sıfırla
      _prefs.setInt('session_duration_today', 0);
      setState(() => _sessionDuration = 0);
      _prefs.setString('last_session_date', today);
    } else {
      setState(() => _sessionDuration = savedTime);
    }
  }

  void _loadStreakDays() async {
    final lastAccessDate = _prefs.getString('last_access_date') ?? '';
    final today = DateTime.now().toString().split(' ')[0];
    final yesterday =
        DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .split(' ')[0];

    int streak = _prefs.getInt('streak_days') ?? 0;

    if (lastAccessDate.isEmpty) {
      // İlk gün
      streak = 1;
    } else if (lastAccessDate == yesterday) {
      // Dün açılmış, streak devam
      streak += 1;
    } else if (lastAccessDate != today) {
      // Aradan gün geçmiş, streak sıfırla
      streak = 1;
    }

    await _prefs.setInt('streak_days', streak);
    await _prefs.setString('last_access_date', today);
    setState(() => _streakDays = streak);
  }

  /// Bugünün başlangıç zamanını al (00:00:00)
  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _loadTaskStats() async {
    final tasksRef = FirebaseFirestore.instance.collection('tasks');
    final snapshot = await tasksRef.where('userId', isEqualTo: userId).get();

    // Sadece bugünün task'larını filtrele (Todo sayfasıyla tutarlı)
    final todayTasks =
        snapshot.docs.where((doc) {
          final createdAt = doc['createdAt'] as Timestamp?;
          if (createdAt == null) return true;
          return createdAt.toDate().isAfter(_todayStart) ||
              createdAt.toDate().isAtSameMomentAs(_todayStart);
        }).toList();

    int completed = todayTasks.where((doc) => doc['completed'] == true).length;
    int total = todayTasks.length;

    if (mounted) {
      setState(() {
        _completedTasks = completed;
        _totalTasks = total;
      });
    }
  }

  void _setupTaskListener() {
    // Eski subscription varsa iptal et
    _taskSubscription?.cancel();

    _taskSubscription = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            // Sadece bugünün task'larını filtrele (Todo sayfasıyla tutarlı)
            final todayTasks =
                snapshot.docs.where((doc) {
                  final createdAt = doc['createdAt'] as Timestamp?;
                  if (createdAt == null) return true;
                  return createdAt.toDate().isAfter(_todayStart) ||
                      createdAt.toDate().isAtSameMomentAs(_todayStart);
                }).toList();

            int completed =
                todayTasks.where((doc) => doc['completed'] == true).length;
            int total = todayTasks.length;
            setState(() {
              _completedTasks = completed;
              _totalTasks = total;
            });
          }
        });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() => _sessionDuration++);

      // Her dakika kaydet
      if (_sessionDuration % 60 == 0) {
        await _prefs.setInt('session_duration_today', _sessionDuration);
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF0F3460),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Language / Dil',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                  dialogContext,
                  'en',
                  'English',
                  currentLocale == 'en',
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  dialogContext,
                  'tr',
                  'Türkçe',
                  currentLocale == 'tr',
                ),
              ],
            ),
          ),
    ).then((selectedLang) {
      // Dialog kapandıktan sonra locale değiştir
      if (selectedLang != null && mounted) {
        // ignore: use_build_context_synchronously
        context.setLocale(Locale(selectedLang));
      }
    });
  }

  Widget _buildLanguageOption(
    BuildContext dialogContext,
    String langCode,
    String langName,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => Navigator.of(dialogContext).pop(langCode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00B4D8).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF00B4D8)
                    : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF00B4D8), size: 20)
            else
              const SizedBox(width: 20),
            const SizedBox(width: 12),
            Text(
              langName,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00B4D8) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _durationTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        title: Text(
          'appTitle'.tr(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Dil seçimi butonu
          GestureDetector(
            onTap: () => _showLanguageDialog(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.language, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Bildirimler butonu
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  builder:
                      (BuildContext dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(24),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logout Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF00B4D8,
                                ).withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                size: 40,
                                color: Color(0xFF00B4D8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title
                            Text(
                              'logout'.tr(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Content
                            Text(
                              'logoutConfirm'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed:
                                        () => Navigator.pop(dialogContext),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'cancel'.tr(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final navigator = Navigator.of(
                                        dialogContext,
                                      );
                                      navigator.pop();
                                      await _authService.signOut();
                                      if (mounted) {
                                        navigator.pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => const LoginPage(),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B4D8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'logout'.tr(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Tab
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        const Color(0xFF00B4D8).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'homeGreeting'.tr(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'homeSubtitle'.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00B4D8,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFF00B4D8),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // İstatistik kartları
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        'homeToday'.tr(),
                        _formatDuration(_sessionDuration),
                        const Color(0xFFE94560),
                        Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildStatCard(
                        'homeTasks'.tr(),
                        '$_completedTasks/$_totalTasks',
                        const Color(0xFF00B4D8),
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildStatCard(
                        'homeStreak'.tr(),
                        '$_streakDays ${'days'.tr()}',
                        const Color(0xFF06A77D),
                        Icons.local_fire_department_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ana özellikler
                Text(
                  'homeFeatures'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                buildCard(
                  context,
                  'pomodoroTitle'.tr(),
                  Icons.schedule_rounded,
                  const Color(0xFFE94560),
                  const PomodoroPage(),
                  'tapToOpen'.tr(),
                ),
                buildCard(
                  context,
                  'todoTitle'.tr(),
                  Icons.checklist_rounded,
                  const Color(0xFF00B4D8),
                  const TodoPage(),
                  'tapToOpen'.tr(),
                ),

                // Alt bilgi
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'homeMotivation'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Analytics Tab
          const AnalyticsPage(),
          // Profile Tab
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A2D4A).withValues(alpha: 0.9),
                    const Color(0xFF0F1E30).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'navHome'.tr(),
                    color: const Color(0xFF00B4D8),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.analytics_rounded,
                    label: 'navAnalytics'.tr(),
                    color: const Color(0xFF06A77D),
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_rounded,
                    label: 'navAccount'.tr(),
                    color: const Color(0xFFE94560),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.15),
                    ],
                  )
                  : null,
          borderRadius: BorderRadius.circular(16),
          border:
              isSelected
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
                  : null,
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white.withValues(alpha: 0.5),
                size: 26,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: SizedBox(width: isSelected ? 8 : 0),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child:
                  isSelected
                      ? Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(
    BuildContext c,
    String title,
    IconData icon,
    Color color,
    Widget page,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.7), color],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

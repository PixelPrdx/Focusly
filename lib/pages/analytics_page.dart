import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late FirebaseFirestore _firestore;
  late String _userId;
  String _selectedPeriod = 'daily'; // daily, weekly, monthly

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<Map<String, dynamic>> _getAnalyticsData() async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    String periodKey;

    if (_selectedPeriod == 'daily') {
      // Bugünün başlangıcı (00:00:00)
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      periodKey = 'analyticsDaily';
    } else if (_selectedPeriod == 'weekly') {
      // Bu haftanın başlangıcı (Pazartesi)
      final weekday = now.weekday;
      startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      periodKey = 'analyticsWeekly';
    } else {
      // Bu ayın başlangıcı
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      periodKey = 'analyticsMonthly';
    }

    try {
      // Pomodoro verilerini al - basit sorgu, client-side filtreleme
      final pomodoroSnapshot =
          await _firestore
              .collection('pomodoro_sessions')
              .where('userId', isEqualTo: _userId)
              .get();

      // Tarih filtreleme client-side
      final filteredPomodoros =
          pomodoroSnapshot.docs.where((doc) {
            final completedAt = doc['completedAt'] as Timestamp?;
            if (completedAt == null) return false;
            final date = completedAt.toDate();
            return (date.isAfter(startDate) ||
                    date.isAtSameMomentAs(startDate)) &&
                (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
          }).toList();

      // Tamamlanan görevleri al - basit sorgu
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: _userId)
              .get();

      // Client-side filtreleme: tamamlanmış ve tarih kontrolü
      final filteredTasks =
          tasksSnapshot.docs.where((doc) {
            final completed = doc['completed'] as bool? ?? false;
            if (!completed) return false;
            final completedAt = doc['completedAt'] as Timestamp?;
            if (completedAt == null) return false;
            final date = completedAt.toDate();
            return (date.isAfter(startDate) ||
                    date.isAtSameMomentAs(startDate)) &&
                (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
          }).toList();

      int pomodoroCount = filteredPomodoros.length;
      int completedTasks = filteredTasks.length;
      int totalPomodoroDuration = filteredPomodoros.fold(
        0,
        (total, doc) => total + (doc['duration'] as int? ?? 25),
      );

      return {
        'pomodoroCount': pomodoroCount,
        'completedTasks': completedTasks,
        'totalDuration': totalPomodoroDuration,
        'periodKey': periodKey,
        'startDate': startDate,
      };
    } catch (e) {
      debugPrint('Analytics Error: $e');
      return {
        'pomodoroCount': 0,
        'completedTasks': 0,
        'totalDuration': 0,
        'periodKey': periodKey,
        'startDate': startDate,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'analyticsTitle'.tr(),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // Period Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPeriodButton('analyticsDaily'.tr(), 'daily'),
                  _buildPeriodButton('analyticsWeekly'.tr(), 'weekly'),
                  _buildPeriodButton('analyticsMonthly'.tr(), 'monthly'),
                ],
              ),
            ),
            // Analytics Content
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getAnalyticsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'analyticsError'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? {};
                  final pomodoroCount = data['pomodoroCount'] as int? ?? 0;
                  final completedTasks = data['completedTasks'] as int? ?? 0;
                  final totalDuration = data['totalDuration'] as int? ?? 0;
                  final periodKey =
                      data['periodKey'] as String? ?? 'analyticsDaily';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Stats Cards
                        _buildStatCard(
                          'analyticsPomodoroSessions'.tr(),
                          pomodoroCount.toString(),
                          const Color(0xFFE94560),
                          Icons.timer,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'analyticsCompletedTasks'.tr(),
                          completedTasks.toString(),
                          const Color(0xFF00B4D8),
                          Icons.done_all,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'analyticsTotalDuration'.tr(),
                          '$totalDuration ${'minutes'.tr()}',
                          const Color(0xFF06A77D),
                          Icons.schedule,
                        ),
                        const SizedBox(height: 24),

                        // Chart Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${periodKey.tr()} ${'analyticsProgress'.tr()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Simple bar chart representation
                              _buildChartBar(
                                'pomodoro'.tr(),
                                pomodoroCount,
                                20,
                                const Color(0xFFE94560),
                              ),
                              const SizedBox(height: 16),
                              _buildChartBar(
                                'taskCompletion'.tr(),
                                completedTasks,
                                20,
                                const Color(0xFF00B4D8),
                              ),
                              const SizedBox(height: 16),
                              _buildChartBar(
                                'workHours'.tr(),
                                (totalDuration ~/ 60),
                                20,
                                const Color(0xFF06A77D),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00B4D8)
                  : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF00B4D8)
                    : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, int value, int maxValue, Color color) {
    final percentage = (value / (maxValue > 0 ? maxValue : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

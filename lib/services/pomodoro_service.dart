import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/constants.dart';

/// Singleton Pomodoro Service - Timer arka planda çalışmaya devam eder
class PomodoroService {
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() => _instance;
  PomodoroService._internal();

  Timer? _timer;
  int _durationMinutes = pomodoroMinutes;
  int _seconds = pomodoroMinutes * 60;
  bool _isRunning = false;
  SharedPreferences? _prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream controller for UI updates
  final _stateController = StreamController<PomodoroState>.broadcast();
  Stream<PomodoroState> get stateStream => _stateController.stream;

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  int get durationMinutes => _durationMinutes;
  int get totalSeconds => _durationMinutes * 60;

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedTime();
  }

  Future<void> _loadSavedTime() async {
    final savedDuration = _prefs?.getInt('pomodoro_duration_minutes');
    if (savedDuration != null) {
      _durationMinutes = savedDuration;
    }

    final savedSeconds = _prefs?.getInt('pomodoro_remaining_seconds');
    final wasRunning = _prefs?.getBool('pomodoro_was_running') ?? false;
    final lastSaveTime = _prefs?.getInt('pomodoro_last_save_time');

    if (savedSeconds != null && savedSeconds > 0) {
      if (wasRunning && lastSaveTime != null) {
        // Timer çalışırken uygulama kapanmış, geçen süreyi hesapla
        final elapsedSeconds =
            ((DateTime.now().millisecondsSinceEpoch - lastSaveTime) / 1000)
                .floor();
        _seconds = (savedSeconds - elapsedSeconds).clamp(
          0,
          _durationMinutes * 60,
        );

        if (_seconds > 0) {
          // Otomatik olarak devam et
          start();
        } else {
          // Süre dolmuş
          _seconds = 0;
          _completePomodoroSession();
        }
      } else {
        _seconds = savedSeconds;
      }
    } else {
      _seconds = _durationMinutes * 60;
    }
    _notifyListeners();
  }

  Future<void> _saveTime() async {
    await _prefs?.setInt('pomodoro_remaining_seconds', _seconds);
    await _prefs?.setBool('pomodoro_was_running', _isRunning);
    await _prefs?.setInt(
      'pomodoro_last_save_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _saveDuration() async {
    await _prefs?.setInt('pomodoro_duration_minutes', _durationMinutes);
  }

  void setDuration(int minutes) {
    if (_isRunning) return; // Çalışırken değiştirme
    _durationMinutes = minutes.clamp(1, 120);
    _seconds = _durationMinutes * 60;
    _saveDuration();
    _saveTime();
    _notifyListeners();
  }

  void start() {
    if (_timer != null && _timer!.isActive) {
      debugPrint('PomodoroService: Timer already running');
      return;
    }

    debugPrint('PomodoroService: Starting timer, seconds: $_seconds');
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        _seconds--;
        _notifyListeners();

        // Her 10 saniyede kaydet
        if (_seconds % 10 == 0) {
          _saveTime();
        }
      } else {
        pause();
        _playCompletionSound();
        _completePomodoroSession();
      }
    });
    _saveTime();
    _notifyListeners();
  }

  void pause() {
    debugPrint('PomodoroService: Pausing timer');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _saveTime();
    _notifyListeners();
  }

  void reset() {
    pause();
    _seconds = _durationMinutes * 60;
    _saveTime();
    _notifyListeners();
  }

  Future<void> _playCompletionSound() async {
    try {
      // Önce URL'den sesi çal (daha güvenilir)
      await _audioPlayer.play(
        UrlSource(
          'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
        ),
        volume: 1.0,
      );
      debugPrint('Alarm sound played successfully');
    } catch (e) {
      debugPrint('Error playing URL sound: $e');
      // Fallback: Yerel dosyadan ses çal
      try {
        await _audioPlayer.play(
          AssetSource('sounds/timer_complete.mp3'),
          volume: 1.0,
        );
      } catch (e2) {
        debugPrint('Local sound also failed: $e2');
      }
    }
  }

  void _notifyListeners() {
    _stateController.add(
      PomodoroState(
        seconds: _seconds,
        isRunning: _isRunning,
        durationMinutes: _durationMinutes,
      ),
    );
  }

  Future<void> _completePomodoroSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('pomodoro_sessions').add({
          'userId': user.uid,
          'duration': _durationMinutes,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }

    // Timer'ı sıfırla
    _seconds = _durationMinutes * 60;
    _saveTime();
    _notifyListeners();
  }

  String get formattedTime {
    final min = (_seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double get progress {
    if (totalSeconds == 0) return 1.0;
    return 1.0 - (_seconds / totalSeconds);
  }

  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _stateController.close();
  }
}

class PomodoroState {
  final int seconds;
  final bool isRunning;
  final int durationMinutes;

  PomodoroState({
    required this.seconds,
    required this.isRunning,
    required this.durationMinutes,
  });
}

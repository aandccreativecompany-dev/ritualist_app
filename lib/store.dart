import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mantras.dart';
import 'models.dart';
import 'notifications.dart';

const _storageKey = 'ritualist_state_v1';

/// Single source of truth. Persists to shared_preferences as one JSON blob.
class Store extends ChangeNotifier {
  AppState _state = AppState.initial();
  bool ready = false;

  AppState get state => _state;

  List<Habit> get habits => _state.habits;
  List<ReminderSetting> get reminders => _state.reminders;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _state = AppState.fromJson(decoded);
        }
      } catch (_) {
        _state = AppState.initial();
      }
    }
    ready = true;
    notifyListeners();
    await rescheduleReminders();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_state.toJson()));
  }

  Future<void> _commit() async {
    notifyListeners();
    await _save();
  }

  // ---- Tasks ----

  List<Task> tasksFor(DateTime date) =>
      _state.tasksByDay[dayKey(date)] ?? <Task>[];

  List<Task> get todaysTasks => tasksFor(DateTime.now());

  int get openTaskCount => todaysTasks.where((t) => !t.done).length;

  Future<void> addTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final key = dayKey(DateTime.now());
    final list = _state.tasksByDay.putIfAbsent(key, () => <Task>[]);
    if (list.length >= 3) return;
    list.add(Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleTask(int index) async {
    final list = _state.tasksByDay[dayKey(DateTime.now())];
    if (list == null || index < 0 || index >= list.length) return;
    list[index].done = !list[index].done;
    await _commit();
  }

  Future<void> removeTask(int index) async {
    final list = _state.tasksByDay[dayKey(DateTime.now())];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _commit();
  }

  // ---- Habits ----

  Future<void> toggleHabit(Habit habit) async {
    habit.toggle(DateTime.now());
    await _commit();
  }

  Future<void> addHabit(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _state.habits.add(Habit(name: trimmed));
    await _commit();
  }

  Future<void> removeHabit(Habit habit) async {
    _state.habits.remove(habit);
    await _commit();
  }

  Future<void> renameHabit(Habit habit, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    habit.name = trimmed;
    await _commit();
  }

  int get habitsDoneToday =>
      _state.habits.where((h) => h.isDoneOn(DateTime.now())).length;

  // ---- Mantra ----

  /// Stable for the whole day, different every day, cycling through the
  /// full sourced quote list before repeating.
  int get _mantraIndex {
    final today = DateTime.now();
    final dayNumber = today.difference(DateTime(2026, 1, 1)).inDays;
    return (dayNumber + _state.mantraSeed) % mantras.length;
  }

  Mantra get mantraEntryOfTheDay => mantras[_mantraIndex.abs()];

  String get mantraOfTheDay => mantraEntryOfTheDay.text;

  // ---- Theme ----

  ThemeMode get themeMode {
    switch (_state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(String mode) async {
    _state.themeMode = mode;
    await _commit();
  }

  // ---- Reminders ----

  Future<void> setReminderEnabled(ReminderSetting reminder, bool value) async {
    reminder.enabled = value;
    await _commit();
    await rescheduleReminders();
  }

  Future<void> setReminderTime(
      ReminderSetting reminder, int hour, int minute) async {
    reminder.hour = hour;
    reminder.minute = minute;
    await _commit();
    await rescheduleReminders();
  }

  Future<void> setSkipWeekends(bool value) async {
    _state.skipWeekends = value;
    await _commit();
    await rescheduleReminders();
  }

  Future<void> rescheduleReminders() async {
    await Notifications.instance.scheduleAll(
      reminders: _state.reminders,
      mantra: mantraOfTheDay,
      openTasks: todaysTasks.where((t) => !t.done).map((t) => t.title).toList(),
    );
  }

  // ---- Onboarding ----

  bool get onboardingComplete => _state.onboardingComplete;

  Future<void> completeOnboarding({
    required List<String> focusAreas,
    required String preset,
  }) async {
    _state.onboardingComplete = true;
    _state.focusAreas = focusAreas;
    _state.preset = preset;
    await _commit();
  }

  Future<void> retakeOnboarding() async {
    _state.onboardingComplete = false;
    await _commit();
  }

  // ---- Module picker (card order + visibility) ----

  List<ModuleConfig> get modules => _state.modules;

  List<String> get visibleModuleIds => _state.modules
      .where((m) => m.enabled)
      .map((m) => m.id)
      .toList(growable: false);

  Future<void> setModuleEnabled(String id, bool enabled) async {
    for (final m in _state.modules) {
      if (m.id == id) m.enabled = enabled;
    }
    await _commit();
  }

  Future<void> reorderModule(int oldIndex, int newIndex) async {
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final item = _state.modules.removeAt(oldIndex);
    _state.modules.insert(to, item);
    await _commit();
  }

  // ---- Scripting (outcome engineering) ----

  List<Script> get scripts => _state.scripts;

  Future<void> addScript(String title, String body) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;
    _state.scripts.insert(0, Script(title: title.trim(), body: body.trim()));
    await _commit();
  }

  Future<void> updateScript(Script script, String title, String body) async {
    script.title = title.trim();
    script.body = body.trim();
    await _commit();
  }

  Future<void> removeScript(Script script) async {
    _state.scripts.remove(script);
    await _commit();
  }

  // ---- Evening reflection (journal) ----

  JournalEntry journalFor(DateTime date) =>
      _state.journalByDay[dayKey(date)] ?? JournalEntry();

  JournalEntry get todaysJournal => journalFor(DateTime.now());

  Future<void> saveTodaysJournal(
      List<String> achievements, String gratitude) async {
    final entry = JournalEntry(achievements: achievements, gratitude: gratitude);
    if (entry.isEmpty) {
      _state.journalByDay.remove(dayKey(DateTime.now()));
    } else {
      _state.journalByDay[dayKey(DateTime.now())] = entry;
    }
    await _commit();
  }

  // ---- Vision board ----

  List<VisionItem> get visionItems => _state.visionItems;

  Future<void> addVisionItem(String caption, {String? imagePath}) async {
    final trimmed = caption.trim();
    if (trimmed.isEmpty && imagePath == null) return;
    _state.visionItems.add(VisionItem(
      caption: trimmed,
      colorIndex: _state.visionItems.length,
      imagePath: imagePath,
    ));
    await _commit();
  }

  Future<void> removeVisionItem(VisionItem item) async {
    _state.visionItems.remove(item);
    await _commit();
  }

  // ---- App lock (PIN + optional biometric) ----

  bool get hasPin => _state.pinHash != null;
  bool get biometricEnabled => _state.biometricEnabled;

  Future<void> setPin(String pin) async {
    _state.pinHash = hashPin(pin);
    await _commit();
  }

  Future<void> clearPin() async {
    _state.pinHash = null;
    _state.biometricEnabled = false;
    await _commit();
  }

  bool verifyPin(String pin) => _state.pinHash == hashPin(pin);

  Future<void> setBiometricEnabled(bool value) async {
    _state.biometricEnabled = value;
    await _commit();
  }

  // ---- Weekly momentum ----

  /// Priorities completed and habit check-ins over the last 7 days, today included.
  ({int prioritiesDone, int prioritiesTotal, int habitChecks, int habitPossible,
      int bestStreak}) weeklyMomentum() {
    final today = DateTime.now();
    var prioritiesDone = 0;
    var prioritiesTotal = 0;
    var habitChecks = 0;
    for (var i = 0; i < 7; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final tasks = tasksFor(day);
      prioritiesTotal += tasks.length;
      prioritiesDone += tasks.where((t) => t.done).length;
      for (final habit in _state.habits) {
        if (habit.isDoneOn(day)) habitChecks++;
      }
    }
    final bestStreak = _state.habits.isEmpty
        ? 0
        : _state.habits.map((h) => h.streak(today)).reduce((a, b) => a > b ? a : b);
    return (
      prioritiesDone: prioritiesDone,
      prioritiesTotal: prioritiesTotal,
      habitChecks: habitChecks,
      habitPossible: _state.habits.length * 7,
      bestStreak: bestStreak,
    );
  }

  // ---- Backup ----

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_state.toJson());

  Future<bool> importJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      _state = AppState.fromJson(decoded);
      await _commit();
      await rescheduleReminders();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final store = Store();

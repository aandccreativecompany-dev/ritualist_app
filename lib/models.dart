// Plain data models. Everything serialises to JSON and lives on the device.

String dayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

class Task {
  String title;
  bool done;

  Task({required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  static Task fromJson(Map<String, dynamic> json) => Task(
        title: (json['title'] ?? '') as String,
        done: (json['done'] ?? false) as bool,
      );
}

class Habit {
  String name;
  List<String> completedDays;

  Habit({required this.name, List<String>? completedDays})
      : completedDays = completedDays ?? <String>[];

  bool isDoneOn(DateTime date) => completedDays.contains(dayKey(date));

  void toggle(DateTime date) {
    final key = dayKey(date);
    if (completedDays.contains(key)) {
      completedDays.remove(key);
    } else {
      completedDays.add(key);
    }
  }

  /// Consecutive days completed, counting back from today.
  int streak(DateTime today) {
    var count = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    while (completedDays.contains(dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int completionsInLast(int days, DateTime today) {
    var count = 0;
    for (var i = 0; i < days; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (completedDays.contains(dayKey(day))) count++;
    }
    return count;
  }

  Map<String, dynamic> toJson() => {'name': name, 'completedDays': completedDays};

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        name: (json['name'] ?? '') as String,
        completedDays: ((json['completedDays'] ?? <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => e.toString())
            .toList(),
      );
}

class ReminderSetting {
  final String id;
  final String title;
  bool enabled;
  int hour;
  int minute;

  ReminderSetting({
    required this.id,
    required this.title,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  String get clockLabel {
    final suffix = hour < 12 ? 'AM' : 'PM';
    var h = hour % 12;
    if (h == 0) h = 12;
    return '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'enabled': enabled, 'hour': hour, 'minute': minute};
}

/// One entry in the outcome-engineering (scripting) list.
class Script {
  String title;
  String body;

  Script({required this.title, required this.body});

  Map<String, dynamic> toJson() => {'title': title, 'body': body};

  static Script fromJson(Map<String, dynamic> json) => Script(
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
      );
}

/// One day's evening reflection.
class JournalEntry {
  /// Up to 3 short "what did I achieve today" lines.
  List<String> achievements;
  String gratitude;

  /// Kept for backward compatibility with entries saved before v0.2 (the
  /// old "anything you want to let go of" prompt) — no longer written to,
  /// but preserved so existing journal history doesn't lose data.
  String reflection;

  JournalEntry({List<String>? achievements, this.gratitude = '', this.reflection = ''})
      : achievements = achievements ?? <String>['', '', ''];

  bool get isEmpty =>
      achievements.every((a) => a.trim().isEmpty) &&
      gratitude.trim().isEmpty &&
      reflection.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'achievements': achievements,
        'gratitude': gratitude,
        'reflection': reflection,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        achievements: (json['achievements'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            <String>['', '', ''],
        gratitude: (json['gratitude'] ?? '') as String,
        reflection: (json['reflection'] ?? '') as String,
      );
}

/// One tile on the vision board — a caption, optionally backed by an image
/// copied into app-local storage from the device's own gallery (e.g. a
/// screenshot saved from Pinterest — the app has no Pinterest integration,
/// there's no public API for pulling their images directly).
class VisionItem {
  String caption;
  int colorIndex;
  String? imagePath;

  VisionItem({required this.caption, this.colorIndex = 0, this.imagePath});

  Map<String, dynamic> toJson() =>
      {'caption': caption, 'colorIndex': colorIndex, 'imagePath': imagePath};

  static VisionItem fromJson(Map<String, dynamic> json) => VisionItem(
        caption: (json['caption'] ?? '') as String,
        colorIndex: (json['colorIndex'] ?? 0) as int,
        imagePath: json['imagePath'] as String?,
      );
}

/// Visibility + order of one home-screen card. Order in the list is display order.
class ModuleConfig {
  final String id;
  bool enabled;

  ModuleConfig({required this.id, this.enabled = true});

  Map<String, dynamic> toJson() => {'id': id, 'enabled': enabled};

  static ModuleConfig fromJson(Map<String, dynamic> json) => ModuleConfig(
        id: (json['id'] ?? '') as String,
        enabled: (json['enabled'] ?? true) as bool,
      );
}

/// Every module the card stack knows how to render, in the default order.
const kAllModuleIds = [
  'mantra',
  'priorities',
  'habits',
  'scripting',
  'eveningReflection',
  'visionBoard',
  'reminders',
];

const kModuleTitles = {
  'mantra': 'Mantra of the day',
  'priorities': 'Top 3 today',
  'habits': 'Habits',
  'scripting': 'Scripting',
  'eveningReflection': 'Evening reflection',
  'visionBoard': 'Vision board',
  'reminders': 'Daily reminders',
};

/// Onboarding presets — set by the quiz, changeable any time from settings.
const kPresetFocus = 'focus';
const kPresetManifest = 'manifest';
const kPresetBalance = 'balance';

/// A small non-cryptographic hash — good enough to check a locally-stored PIN
/// without keeping it as plain text. This is not encryption; the journal lock
/// is a privacy nudge, not a security boundary, exactly like the design intends.
String hashPin(String pin) {
  var hash = 5381;
  for (final unit in pin.codeUnits) {
    hash = ((hash << 5) + hash + unit) & 0x7fffffff;
  }
  return hash.toRadixString(16);
}

class AppState {
  Map<String, List<Task>> tasksByDay;
  List<Habit> habits;
  List<ReminderSetting> reminders;
  int mantraSeed;
  String themeMode;
  bool skipWeekends;

  bool onboardingComplete;
  List<String> focusAreas;
  String preset;
  List<ModuleConfig> modules;

  List<Script> scripts;
  Map<String, JournalEntry> journalByDay;
  List<VisionItem> visionItems;

  String? pinHash;
  bool biometricEnabled;

  AppState({
    required this.tasksByDay,
    required this.habits,
    required this.reminders,
    required this.mantraSeed,
    required this.themeMode,
    required this.skipWeekends,
    required this.onboardingComplete,
    required this.focusAreas,
    required this.preset,
    required this.modules,
    required this.scripts,
    required this.journalByDay,
    required this.visionItems,
    required this.pinHash,
    required this.biometricEnabled,
  });

  static AppState initial() => AppState(
        tasksByDay: <String, List<Task>>{},
        habits: [
          Habit(name: 'Morning pages'),
          Habit(name: 'Walk 30 minutes'),
          Habit(name: 'No phone before 9am'),
        ],
        reminders: [
          ReminderSetting(
              id: 'mantra',
              title: 'Mantra of the day',
              enabled: true,
              hour: 7,
              minute: 30),
          ReminderSetting(
              id: 'midday',
              title: 'Midday task check',
              enabled: true,
              hour: 13,
              minute: 0),
          ReminderSetting(
              id: 'evening',
              title: 'Evening close',
              enabled: true,
              hour: 21,
              minute: 0),
        ],
        mantraSeed: DateTime.now().millisecondsSinceEpoch % 997,
        themeMode: 'system',
        skipWeekends: false,
        onboardingComplete: false,
        focusAreas: <String>[],
        preset: kPresetBalance,
        modules: [for (final id in kAllModuleIds) ModuleConfig(id: id)],
        scripts: <Script>[],
        journalByDay: <String, JournalEntry>{},
        visionItems: <VisionItem>[],
        pinHash: null,
        biometricEnabled: false,
      );

  Map<String, dynamic> toJson() => {
        'tasksByDay': tasksByDay.map((key, value) =>
            MapEntry(key, value.map((t) => t.toJson()).toList())),
        'habits': habits.map((h) => h.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'mantraSeed': mantraSeed,
        'themeMode': themeMode,
        'skipWeekends': skipWeekends,
        'onboardingComplete': onboardingComplete,
        'focusAreas': focusAreas,
        'preset': preset,
        'modules': modules.map((m) => m.toJson()).toList(),
        'scripts': scripts.map((s) => s.toJson()).toList(),
        'journalByDay':
            journalByDay.map((key, value) => MapEntry(key, value.toJson())),
        'visionItems': visionItems.map((v) => v.toJson()).toList(),
        'pinHash': pinHash,
        'biometricEnabled': biometricEnabled,
      };

  static AppState fromJson(Map<String, dynamic> json) {
    final state = initial();

    final rawTasks = json['tasksByDay'];
    if (rawTasks is Map) {
      final parsed = <String, List<Task>>{};
      rawTasks.forEach((key, value) {
        if (value is List) {
          parsed[key.toString()] = value
              .whereType<Map<String, dynamic>>()
              .map(Task.fromJson)
              .toList();
        }
      });
      state.tasksByDay = parsed;
    }

    final rawHabits = json['habits'];
    if (rawHabits is List) {
      state.habits = rawHabits
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList();
    }

    final rawReminders = json['reminders'];
    if (rawReminders is List) {
      for (final entry in rawReminders.whereType<Map<String, dynamic>>()) {
        final match = state.reminders
            .where((r) => r.id == (entry['id'] ?? '').toString())
            .toList();
        if (match.isEmpty) continue;
        final reminder = match.first;
        reminder.enabled = (entry['enabled'] ?? reminder.enabled) as bool;
        reminder.hour = (entry['hour'] ?? reminder.hour) as int;
        reminder.minute = (entry['minute'] ?? reminder.minute) as int;
      }
    }

    if (json['mantraSeed'] is int) state.mantraSeed = json['mantraSeed'] as int;
    if (json['themeMode'] is String) {
      state.themeMode = json['themeMode'] as String;
    }
    if (json['skipWeekends'] is bool) {
      state.skipWeekends = json['skipWeekends'] as bool;
    }

    if (json['onboardingComplete'] is bool) {
      state.onboardingComplete = json['onboardingComplete'] as bool;
    }
    final rawFocus = json['focusAreas'];
    if (rawFocus is List) {
      state.focusAreas = rawFocus.map((e) => e.toString()).toList();
    }
    if (json['preset'] is String) state.preset = json['preset'] as String;

    final rawModules = json['modules'];
    if (rawModules is List && rawModules.isNotEmpty) {
      final parsed = rawModules
          .whereType<Map<String, dynamic>>()
          .map(ModuleConfig.fromJson)
          .where((m) => kAllModuleIds.contains(m.id))
          .toList();
      // Keep every known module even if an old backup predates it.
      for (final id in kAllModuleIds) {
        if (!parsed.any((m) => m.id == id)) parsed.add(ModuleConfig(id: id));
      }
      state.modules = parsed;
    }

    final rawScripts = json['scripts'];
    if (rawScripts is List) {
      state.scripts = rawScripts
          .whereType<Map<String, dynamic>>()
          .map(Script.fromJson)
          .toList();
    }

    final rawJournal = json['journalByDay'];
    if (rawJournal is Map) {
      final parsed = <String, JournalEntry>{};
      rawJournal.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsed[key.toString()] = JournalEntry.fromJson(value);
        }
      });
      state.journalByDay = parsed;
    }

    final rawVision = json['visionItems'];
    if (rawVision is List) {
      state.visionItems = rawVision
          .whereType<Map<String, dynamic>>()
          .map(VisionItem.fromJson)
          .toList();
    }

    if (json['pinHash'] is String) state.pinHash = json['pinHash'] as String;
    if (json['biometricEnabled'] is bool) {
      state.biometricEnabled = json['biometricEnabled'] as bool;
    }

    return state;
  }
}

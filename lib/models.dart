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

/// Curated icons a habit can carry — index into this list is what's stored.
const List<String> kHabitIconNames = [
  'edit_note', // journaling
  'directions_walk', // movement
  'self_improvement', // meditation
  'water_drop', // hydration
  'menu_book', // reading
  'bedtime', // sleep
  'no_cell', // screen-free
  'restaurant', // eating/nutrition
  'fitness_center', // exercise
  'favorite', // gratitude / wellbeing
  'wb_sunny', // morning routine
  'volunteer_activism', // kindness/giving
];

/// Monotonically increasing so two habits created in the same microsecond
/// still get distinct ids.
int _habitIdSeq = 0;
String _newHabitId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_habitIdSeq++}';

class Habit {
  /// Stable identity, independent of object reference — list keys and
  /// add/remove/edit lookups use this instead of instance equality, so they
  /// keep working correctly across rebuilds and JSON round-trips.
  final String id;
  String name;
  List<String> completedDays;
  int iconIndex;
  int colorIndex;

  Habit({
    String? id,
    required this.name,
    List<String>? completedDays,
    this.iconIndex = 0,
    this.colorIndex = 0,
  })  : id = id ?? _newHabitId(),
        completedDays = completedDays ?? <String>[];

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'completedDays': completedDays,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
      };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String?,
        name: (json['name'] ?? '') as String,
        completedDays: ((json['completedDays'] ?? <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => e.toString())
            .toList(),
        iconIndex: (json['iconIndex'] ?? 0) as int,
        colorIndex: (json['colorIndex'] ?? 0) as int,
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
  'tips',
  'scripting',
  'eveningReflection',
  'visionBoard',
  'reminders',
];

const kModuleTitles = {
  'mantra': 'Mantra of the day',
  'priorities': 'Goals & to-dos',
  'habits': 'Habits',
  'tips': 'Productivity tip',
  'scripting': 'Scripting',
  'eveningReflection': 'Evening reflection',
  'visionBoard': 'Vision board',
  'reminders': 'Daily reminders',
};

/// The five habits every fresh install starts with — still fully editable
/// and deletable, just a friendlier starting point than an empty list.
List<Habit> defaultHabits() => [
      Habit(name: 'Exercise', iconIndex: 8, colorIndex: 0),
      Habit(name: 'Read 10 pages', iconIndex: 4, colorIndex: 1),
      Habit(name: 'Get sunlight', iconIndex: 10, colorIndex: 2),
      Habit(name: 'Personal care', iconIndex: 9, colorIndex: 3),
      Habit(name: 'Learn something new', iconIndex: 2, colorIndex: 4),
    ];

/// Vision board tile shapes the user can switch between.
const kVisionShapes = ['square', 'circle', 'star'];

/// Which section of the two-card home ("Productivity" / "Outcome
/// engineering") each module lives in. `mantra` isn't listed — it sits
/// above both as a standalone banner, not inside either section.
const kProductivityModuleIds = ['priorities', 'habits', 'tips', 'reminders'];
const kOutcomeModuleIds = ['scripting', 'eveningReflection', 'visionBoard'];

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
  String userName;
  List<String> focusAreas;
  String dailyTimeCommitment;
  String preset;
  List<ModuleConfig> modules;

  List<Script> scripts;
  Map<String, JournalEntry> journalByDay;
  List<VisionItem> visionItems;

  String? pinHash;
  bool biometricEnabled;

  /// Day (`dayKey` string) the morning mood check-in was last shown, so it
  /// asks at most once per day. `moodByDay` holds what was picked.
  String? lastMoodPromptDay;
  Map<String, String> moodByDay;

  /// Day the evening reflection popup was last shown/dismissed, so it also
  /// asks at most once per day rather than nagging every time home opens.
  String? lastEveningPromptDay;

  /// Standalone goal lists, separate from the daily task list — surfaced via
  /// the three floating quick-launch buttons on the Productivity section.
  List<Task> weeklyGoals;
  List<Task> monthlyGoals;

  /// Which cartoon character greets the user on open, chosen during setup.
  String avatarGender;

  /// Vision board tile shape: 'square' | 'circle' | 'star'.
  String visionBoardShape;

  AppState({
    required this.tasksByDay,
    required this.habits,
    required this.reminders,
    required this.mantraSeed,
    required this.themeMode,
    required this.skipWeekends,
    required this.onboardingComplete,
    required this.userName,
    required this.focusAreas,
    required this.dailyTimeCommitment,
    required this.preset,
    required this.modules,
    required this.scripts,
    required this.journalByDay,
    required this.visionItems,
    required this.pinHash,
    required this.biometricEnabled,
    required this.lastMoodPromptDay,
    required this.moodByDay,
    required this.lastEveningPromptDay,
    required this.weeklyGoals,
    required this.monthlyGoals,
    required this.avatarGender,
    required this.visionBoardShape,
  });

  static AppState initial() => AppState(
        tasksByDay: <String, List<Task>>{},
        habits: defaultHabits(),
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
        userName: '',
        focusAreas: <String>[],
        dailyTimeCommitment: '',
        preset: kPresetBalance,
        modules: [for (final id in kAllModuleIds) ModuleConfig(id: id)],
        scripts: <Script>[],
        journalByDay: <String, JournalEntry>{},
        visionItems: <VisionItem>[],
        pinHash: null,
        biometricEnabled: false,
        lastMoodPromptDay: null,
        moodByDay: <String, String>{},
        lastEveningPromptDay: null,
        weeklyGoals: <Task>[],
        monthlyGoals: <Task>[],
        avatarGender: 'girl',
        visionBoardShape: 'square',
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
        'userName': userName,
        'focusAreas': focusAreas,
        'dailyTimeCommitment': dailyTimeCommitment,
        'preset': preset,
        'modules': modules.map((m) => m.toJson()).toList(),
        'scripts': scripts.map((s) => s.toJson()).toList(),
        'journalByDay':
            journalByDay.map((key, value) => MapEntry(key, value.toJson())),
        'visionItems': visionItems.map((v) => v.toJson()).toList(),
        'pinHash': pinHash,
        'biometricEnabled': biometricEnabled,
        'lastMoodPromptDay': lastMoodPromptDay,
        'moodByDay': moodByDay,
        'lastEveningPromptDay': lastEveningPromptDay,
        'weeklyGoals': weeklyGoals.map((t) => t.toJson()).toList(),
        'monthlyGoals': monthlyGoals.map((t) => t.toJson()).toList(),
        'avatarGender': avatarGender,
        'visionBoardShape': visionBoardShape,
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
    if (json['userName'] is String) state.userName = json['userName'] as String;
    final rawFocus = json['focusAreas'];
    if (rawFocus is List) {
      state.focusAreas = rawFocus.map((e) => e.toString()).toList();
    }
    if (json['dailyTimeCommitment'] is String) {
      state.dailyTimeCommitment = json['dailyTimeCommitment'] as String;
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
    if (json['lastMoodPromptDay'] is String) {
      state.lastMoodPromptDay = json['lastMoodPromptDay'] as String;
    }
    final rawMood = json['moodByDay'];
    if (rawMood is Map) {
      state.moodByDay = rawMood.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (json['lastEveningPromptDay'] is String) {
      state.lastEveningPromptDay = json['lastEveningPromptDay'] as String;
    }

    final rawWeekly = json['weeklyGoals'];
    if (rawWeekly is List) {
      state.weeklyGoals =
          rawWeekly.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    final rawMonthly = json['monthlyGoals'];
    if (rawMonthly is List) {
      state.monthlyGoals =
          rawMonthly.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    if (json['avatarGender'] is String) {
      state.avatarGender = json['avatarGender'] as String;
    }
    if (json['visionBoardShape'] is String &&
        kVisionShapes.contains(json['visionBoardShape'])) {
      state.visionBoardShape = json['visionBoardShape'] as String;
    }

    return state;
  }
}

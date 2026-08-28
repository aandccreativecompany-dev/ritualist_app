// Plain data models. Everything serialises to JSON and lives on the device.

import 'theme.dart' show kAccentPalettes, kFontFamilies, kFontScales;

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

/// One short colorful sticky note pinned onto the organized mind map.
class MindMapStickyNote {
  String id;
  String text;
  int colorIndex;

  MindMapStickyNote({required this.id, required this.text, this.colorIndex = 0});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'colorIndex': colorIndex};

  static MindMapStickyNote? fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String || text.isEmpty) return null;
    final id = json['id'];
    final colorIndex = json['colorIndex'];
    return MindMapStickyNote(
      id: id is String && id.isNotEmpty ? id : '${text.hashCode}',
      text: text,
      colorIndex: colorIndex is int ? colorIndex : 0,
    );
  }
}

/// One customizable spending category header (e.g. "Food") with its own
/// customizable sub-headers (e.g. "Groceries", "Dining out") — per the
/// explicit ask that both levels be user-editable, not a fixed list.
class SpendCategory {
  String id;
  String name;
  List<String> subcategories;

  SpendCategory({required this.id, required this.name, List<String>? subcategories})
      : subcategories = subcategories ?? [];

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'subcategories': subcategories};

  static SpendCategory? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.isEmpty) return null;
    final id = json['id'];
    final rawSubs = json['subcategories'];
    return SpendCategory(
      id: id is String && id.isNotEmpty ? id : '${name.hashCode}',
      name: name,
      subcategories: rawSubs is List ? rawSubs.map((e) => e.toString()).toList() : [],
    );
  }
}

/// One logged expense — tagged Need or Want per the explicit ask, so the
/// tracker can show not just "where the money went" but "how much of it
/// was actually necessary."
class SpendEntry {
  String id;
  String categoryId;
  String subcategory;
  double amount;
  bool isNeed;
  String note;
  DateTime date;

  SpendEntry({
    required this.id,
    required this.categoryId,
    this.subcategory = '',
    required this.amount,
    required this.isNeed,
    this.note = '',
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'subcategory': subcategory,
        'amount': amount,
        'isNeed': isNeed,
        'note': note,
        'date': date.toIso8601String(),
      };

  static SpendEntry? fromJson(Map<String, dynamic> json) {
    final categoryId = json['categoryId'];
    final amount = json['amount'];
    if (categoryId is! String || categoryId.isEmpty) return null;
    final parsedAmount = amount is num ? amount.toDouble() : double.tryParse('$amount');
    if (parsedAmount == null || parsedAmount <= 0) return null;
    final id = json['id'];
    final rawDate = json['date'];
    final parsedDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    return SpendEntry(
      id: id is String && id.isNotEmpty
          ? id
          : '${DateTime.now().microsecondsSinceEpoch}',
      categoryId: categoryId,
      subcategory: json['subcategory'] is String ? json['subcategory'] as String : '',
      amount: parsedAmount,
      isNeed: json['isNeed'] == true,
      note: json['note'] is String ? json['note'] as String : '',
      date: parsedDate ?? DateTime.now(),
    );
  }
}

/// A yearly recurring reminder for one date — a birthday, an anniversary,
/// a renewal, anything that matters once a year — separate from the daily
/// reminders above. Only month/day are kept (no year), since it repeats
/// every year by definition; the next occurrence is computed at schedule
/// time (this year if it hasn't passed yet, else next year).
class KeyDate {
  String id;
  String title;
  int month; // 1-12
  int day; // 1-31 (clamped to a day that exists in that month when scheduled)

  KeyDate({
    required this.id,
    required this.title,
    required this.month,
    required this.day,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'month': month, 'day': day};

  static KeyDate? fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final month = json['month'];
    final day = json['day'];
    if (title is! String || month is! int || day is! int) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final id = json['id'];
    return KeyDate(
      id: id is String && id.isNotEmpty ? id : '$month-$day-${title.hashCode}',
      title: title,
      month: month,
      day: day,
    );
  }
}

/// One entry in the Journaling (Brain Dump) list — either a manifestation
/// script (write the outcome as if it already happened) or a free-form
/// brain dump. [mode] is 'manifest' or 'dump'; unknown/legacy values are
/// treated as 'manifest' so entries saved before this field existed still
/// display correctly.
class Script {
  String title;
  String body;
  String mode;

  /// When this script was first saved — shown on its card so it's obvious
  /// at a glance that saving actually happened, not just a passing toast.
  DateTime createdAt;

  Script({
    required this.title,
    required this.body,
    this.mode = 'manifest',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'mode': mode,
        'createdAt': createdAt.toIso8601String(),
      };

  static Script fromJson(Map<String, dynamic> json) => Script(
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        mode: (json['mode'] ?? 'manifest') as String,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

/// A finance "Goal Roadmap": one dream goal broken into monthly milestones,
/// each a simple checkbox — matches the Dream Goal → 12-Month Goal →
/// Monthly Milestones flow from the reference roadmap graphic.
class FinanceRoadmap {
  String dreamGoal;
  double targetAmount;
  int months;
  List<bool> monthsDone;

  // Clamped to a sane range — an unbounded value here (a stray extra digit
  // typed into the months field, or a corrupted backup) would otherwise
  // build one milestone-circle widget per month and could make the Finance
  // page freeze or crash after the number gets large enough.
  FinanceRoadmap({
    required this.dreamGoal,
    required this.targetAmount,
    required int months,
    List<bool>? monthsDone,
  })  : months = months.clamp(1, 360),
        monthsDone = monthsDone ?? List<bool>.filled(months.clamp(1, 360), false);

  double get perMonth => months == 0 ? 0 : targetAmount / months;
  int get monthsCompleted => monthsDone.where((d) => d).length;
  double get savedSoFar => perMonth * monthsCompleted;

  Map<String, dynamic> toJson() => {
        'dreamGoal': dreamGoal,
        'targetAmount': targetAmount,
        'months': months,
        'monthsDone': monthsDone,
      };

  static FinanceRoadmap fromJson(Map<String, dynamic> json) {
    final rawMonths = json['months'];
    final months = (rawMonths is int
            ? rawMonths
            : (rawMonths is num ? rawMonths.toInt() : 12))
        .clamp(1, 360);
    final rawDone = json['monthsDone'];
    final done = rawDone is List
        ? rawDone.map((e) => e == true).toList()
        : List<bool>.filled(months, false);
    while (done.length < months) {
      done.add(false);
    }
    return FinanceRoadmap(
      dreamGoal: (json['dreamGoal'] ?? '') as String,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      months: months,
      monthsDone: done,
    );
  }
}

/// A user-written "instead of / try" pair for the Thought Reframe tool —
/// supplements the built-in reference pairs shown alongside it.
class Reframe {
  String negative;
  String positive;
  Reframe({required this.negative, required this.positive});

  Map<String, dynamic> toJson() => {'negative': negative, 'positive': positive};

  static Reframe fromJson(Map<String, dynamic> json) => Reframe(
        negative: (json['negative'] ?? '') as String,
        positive: (json['positive'] ?? '') as String,
      );
}

/// Reference "instead of / try" pairs for the Thought Reframe tool.
const kReframePairs = [
  ('I don’t want to make a mistake.', 'Mistakes help me learn and grow.'),
  ('I can’t do it.', 'I will keep trying.'),
  ('I give up.', 'I believe in me.'),
  ('They are better at it than me.', 'What can I learn from them?'),
  ('This is too hard.', 'With more practice it will get easier.'),
];

/// Stress Bucket reference items — what fills it vs. what empties it.
const kStressFillItems = [
  'Worries',
  'Too much work',
  'Lack of sleep',
  'Overthinking',
  'Pressure & expectations',
];
const kStressEmptyItems = [
  'Talking about it',
  'Taking breaks',
  'Listening to music',
  'Exercise',
  'Spending time with loved ones',
  'Doing things you enjoy',
];

/// Daily DOSE reference activities, grouped by the "feel-good" chemical
/// each one nudges — dopamine, oxytocin, serotonin, endorphins.
const kDoseCategories = [
  ('Dopamine', 'The reward chemical', ['Create something', 'Achieve a goal', 'Finish a task']),
  ('Oxytocin', 'The love hormone', ['Socialize', 'Hug a family member or pet', 'Help others']),
  ('Serotonin', 'The mood stabiliser', ['Get out in sunlight', 'Try mindfulness', 'Try meditation']),
  ('Endorphins', 'The pain killer', ['Exercise', 'Listen to music', 'Watch a movie', 'Have a laugh']),
];

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

  /// Per-tile shape — one of [kVisionShapes]. Empty string means "use the
  /// board's default shape" (back-compat with boards saved before every tile
  /// could have its own shape).
  String shape;

  /// How many grid cells this tile spans, out of the masonry grid's fixed
  /// column count — lets tiles be small, wide, tall, or large instead of
  /// uniform squares.
  int spanX;
  int spanY;

  /// Where the image is centred inside its tile (0..1 fractional alignment)
  /// and how far it's zoomed in — set by dragging/pinching in the tile editor
  /// so a photo can be recomposed after the tile's shape or size changes.
  double imageOffsetX;
  double imageOffsetY;
  double imageZoom;

  VisionItem({
    required this.caption,
    this.colorIndex = 0,
    this.imagePath,
    this.shape = '',
    this.spanX = 1,
    this.spanY = 1,
    this.imageOffsetX = 0.5,
    this.imageOffsetY = 0.5,
    this.imageZoom = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'colorIndex': colorIndex,
        'imagePath': imagePath,
        'shape': shape,
        'spanX': spanX,
        'spanY': spanY,
        'imageOffsetX': imageOffsetX,
        'imageOffsetY': imageOffsetY,
        'imageZoom': imageZoom,
      };

  static VisionItem fromJson(Map<String, dynamic> json) => VisionItem(
        caption: (json['caption'] ?? '') as String,
        colorIndex: (json['colorIndex'] ?? 0) as int,
        imagePath: json['imagePath'] as String?,
        shape: (json['shape'] ?? '') as String,
        spanX: (json['spanX'] ?? 1) as int,
        spanY: (json['spanY'] ?? 1) as int,
        imageOffsetX: ((json['imageOffsetX'] ?? 0.5) as num).toDouble(),
        imageOffsetY: ((json['imageOffsetY'] ?? 0.5) as num).toDouble(),
        imageZoom: ((json['imageZoom'] ?? 1.0) as num).toDouble(),
      );
}

/// One curated arrangement of tile shapes/sizes a user can apply to their
/// vision board in one tap, grouped into [kVisionLayoutCategories].
class VisionLayoutSpec {
  final String name;
  final String category;
  final List<(String shape, int spanX, int spanY)> slots;
  const VisionLayoutSpec({required this.name, required this.category, required this.slots});
}

/// ~25 layouts across 5 categories, each a short recipe of (shape, spanX,
/// spanY) slots. Applying one assigns its slots to the user's existing tiles
/// in order (cycling if there are more tiles than slots).
const kVisionLayoutCategories = [
  'Classic Grid',
  'Photo Collage',
  'Mosaic',
  'Minimal',
  'Bold & Playful',
];

const List<VisionLayoutSpec> kVisionLayouts = [
  // Classic Grid — even, uniform, calm.
  VisionLayoutSpec(name: 'Even Squares', category: 'Classic Grid', slots: [
    ('square', 1, 1), ('square', 1, 1), ('square', 1, 1), ('square', 1, 1),
    ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Rounded Rows', category: 'Classic Grid', slots: [
    ('roundedRect', 2, 1), ('roundedRect', 2, 1), ('roundedRect', 2, 1),
  ]),
  VisionLayoutSpec(name: 'Circle Grid', category: 'Classic Grid', slots: [
    ('circle', 1, 1), ('circle', 1, 1), ('circle', 1, 1), ('circle', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Two Columns', category: 'Classic Grid', slots: [
    ('square', 1, 1), ('square', 1, 1), ('roundedRect', 2, 1),
    ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Wide Banner', category: 'Classic Grid', slots: [
    ('roundedRect', 2, 1), ('square', 1, 1), ('square', 1, 1),
    ('square', 1, 1), ('square', 1, 1),
  ]),
  // Photo Collage — one hero tile plus scattered smaller ones.
  VisionLayoutSpec(name: 'Hero + Grid', category: 'Photo Collage', slots: [
    ('roundedRect', 2, 2), ('square', 1, 1), ('square', 1, 1),
    ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Corner Focus', category: 'Photo Collage', slots: [
    ('square', 1, 1), ('roundedRect', 2, 2), ('square', 1, 1),
    ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Center Stage', category: 'Photo Collage', slots: [
    ('circle', 1, 1), ('roundedRect', 2, 2), ('circle', 1, 1),
    ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Story Wall', category: 'Photo Collage', slots: [
    ('roundedRect', 1, 2), ('square', 1, 1), ('square', 1, 1),
    ('roundedRect', 1, 2), ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Scrapbook', category: 'Photo Collage', slots: [
    ('star', 1, 1), ('square', 1, 1), ('roundedRect', 2, 1),
    ('circle', 1, 1), ('square', 1, 1),
  ]),
  // Mosaic — varied spans, denser, more textured.
  VisionLayoutSpec(name: 'Brick Mosaic', category: 'Mosaic', slots: [
    ('square', 1, 1), ('square', 1, 1), ('roundedRect', 2, 1),
    ('roundedRect', 2, 1), ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Staircase', category: 'Mosaic', slots: [
    ('square', 1, 1), ('roundedRect', 1, 2), ('square', 1, 1),
    ('roundedRect', 1, 2), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Puzzle', category: 'Mosaic', slots: [
    ('hexagon', 1, 1), ('hexagon', 1, 1), ('roundedRect', 2, 1),
    ('hexagon', 1, 1), ('hexagon', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Uneven Rows', category: 'Mosaic', slots: [
    ('roundedRect', 2, 1), ('square', 1, 1), ('square', 1, 1),
    ('square', 1, 1), ('roundedRect', 2, 1),
  ]),
  VisionLayoutSpec(name: 'Cluster', category: 'Mosaic', slots: [
    ('circle', 1, 1), ('square', 1, 1), ('circle', 1, 1),
    ('roundedRect', 2, 1), ('circle', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Diamond Cluster', category: 'Mosaic', slots: [
    ('diamond', 1, 1), ('diamond', 1, 1), ('roundedRect', 2, 1),
    ('diamond', 1, 1),
  ]),
  // Minimal — a few large, breathing tiles.
  VisionLayoutSpec(name: 'One Big Focus', category: 'Minimal', slots: [
    ('roundedRect', 2, 2),
  ]),
  VisionLayoutSpec(name: 'Two Pillars', category: 'Minimal', slots: [
    ('roundedRect', 1, 2), ('roundedRect', 1, 2),
  ]),
  VisionLayoutSpec(name: 'Simple Trio', category: 'Minimal', slots: [
    ('square', 1, 1), ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Wide & Clean', category: 'Minimal', slots: [
    ('roundedRect', 2, 1), ('roundedRect', 2, 1),
  ]),
  VisionLayoutSpec(name: 'Single Circle Focus', category: 'Minimal', slots: [
    ('circle', 2, 2),
  ]),
  // Bold & Playful — stars, hearts, diamonds, mixed shapes.
  VisionLayoutSpec(name: 'Star Power', category: 'Bold & Playful', slots: [
    ('star', 1, 1), ('star', 1, 1), ('roundedRect', 2, 1), ('star', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Heart of It', category: 'Bold & Playful', slots: [
    ('heart', 2, 2), ('square', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Mixed Shapes', category: 'Bold & Playful', slots: [
    ('star', 1, 1), ('circle', 1, 1), ('heart', 1, 1),
    ('diamond', 1, 1), ('hexagon', 1, 1), ('square', 1, 1),
  ]),
  VisionLayoutSpec(name: 'Celebration', category: 'Bold & Playful', slots: [
    ('star', 1, 1), ('heart', 1, 1), ('roundedRect', 2, 1),
    ('star', 1, 1), ('heart', 1, 1),
  ]),
];

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
  'mindMap',
  'reminders',
  'financeGoals',
  'healthGoals',
  'mindsetGoals',
  'relationshipsGoals',
];

const kModuleTitles = {
  'mantra': 'Mantra of the day',
  'priorities': 'Goals & to-dos',
  'habits': 'Habits',
  'tips': 'Productivity tip',
  'scripting': 'Journaling (Brain Dump)',
  'eveningReflection': 'Evening reflection',
  'visionBoard': 'Vision board',
  'mindMap': 'Organized mind map',
  'reminders': 'Daily reminders',
  'financeGoals': 'Finance & money goals',
  'healthGoals': 'Health & body',
  'mindsetGoals': 'Mindset & growth',
  'relationshipsGoals': 'Relationships & connection',
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

/// Starting set of spending categories — fully editable afterward (rename,
/// delete, add more, edit sub-headers) per the explicit ask that this not
/// be a fixed list.
List<SpendCategory> defaultSpendCategories() => [
      SpendCategory(id: 'food', name: 'Food', subcategories: ['Groceries', 'Dining out']),
      SpendCategory(id: 'transport', name: 'Transport', subcategories: ['Fuel', 'Public transit']),
      SpendCategory(id: 'shopping', name: 'Shopping', subcategories: ['Clothing', 'Electronics']),
      SpendCategory(id: 'bills', name: 'Bills', subcategories: ['Rent', 'Utilities', 'Subscriptions']),
      SpendCategory(id: 'other', name: 'Other', subcategories: []),
    ];

/// Vision board tile shapes the user can switch between — either as the
/// board-wide default or per individual tile.
const kVisionShapes = [
  'square',
  'circle',
  'star',
  'heart',
  'hexagon',
  'diamond',
  'roundedRect',
];

const kVisionShapeLabels = {
  'square': 'Square',
  'circle': 'Circle',
  'star': 'Star',
  'heart': 'Heart',
  'hexagon': 'Hexagon',
  'diamond': 'Diamond',
  'roundedRect': 'Wide',
};

/// Which section of the swipeable home each module lives in. `mantra` isn't
/// listed — it sits above every section as a standalone banner.
const kProductivityModuleIds = ['priorities', 'habits', 'tips', 'reminders'];
const kOutcomeModuleIds = ['scripting', 'eveningReflection', 'visionBoard', 'mindMap'];
const kFinanceModuleIds = ['financeGoals'];
const kHealthModuleIds = ['healthGoals'];
const kMindsetModuleIds = ['mindsetGoals'];
const kRelationshipsModuleIds = ['relationshipsGoals'];

/// One swipeable section of the home screen — bundles its title and the
/// module ids it holds so home_screen.dart's page-building and the
/// Settings "starting screen" picker both read from one shared list instead
/// of duplicating the section order in two places.
class HomePageSection {
  final String key;
  final String title;
  final List<String> moduleIds;
  const HomePageSection(this.key, this.title, this.moduleIds);
}

const kHomePageSections = [
  HomePageSection('productivity', 'Productivity', kProductivityModuleIds),
  HomePageSection('outcome', 'Outcome engineering', kOutcomeModuleIds),
  HomePageSection('finance', 'Finance & money', kFinanceModuleIds),
  HomePageSection('health', 'Health & body', kHealthModuleIds),
  HomePageSection('mindset', 'Mindset & growth', kMindsetModuleIds),
  HomePageSection('relationships', 'Relationships & connection', kRelationshipsModuleIds),
];

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
  List<KeyDate> keyDates;
  int mantraSeed;
  String themeMode;
  bool skipWeekends;

  /// Which of [kAccentPalettes] (theme.dart) the user picked for the app's
  /// accent color — 'gold' is the original look and stays the default.
  String themeAccentId;

  /// Which of [kFontFamilies] / [kFontScales] (theme.dart) the user picked
  /// for body text readability — 'inter'/'default' are the original look.
  String fontFamilyId;
  String fontScaleId;

  /// Which [kHomePageSections] key opens first when the app launches.
  /// 'productivity' (the original behavior) is the default.
  String defaultPageKey;

  /// Chosen interval, in seconds, for the exercise interval bell timer.
  int exerciseBellIntervalSeconds;

  /// Wallet / spending tracker — user-customizable category headers (each
  /// with its own customizable sub-headers) and the logged expenses
  /// against them, each tagged Need or Want.
  List<SpendCategory> spendCategories;
  List<SpendEntry> spendEntries;

  /// The collaborative shared vision board this device last created or
  /// joined, if any — cached locally so re-opening the screen doesn't
  /// require re-entering the code every time.
  String? sharedBoardCode;
  String? sharedBoardTitle;

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

  /// Vision board's default tile shape — used for any tile that hasn't set
  /// its own individual shape.
  String visionBoardShape;

  /// Name of the layout last applied from the 25-template gallery, purely
  /// informational (shown as "Currently: <name>" in the picker).
  String? visionBoardLayoutName;

  /// Finance & Money, Health & Body, Mindset & Growth and Relationships &
  /// Connection are simple goal checklists, same shape as weekly/monthly
  /// goals, each its own swipeable home card.
  List<Task> financeGoals;
  List<Task> healthGoals;
  List<Task> mindsetGoals;
  List<Task> relationshipsGoals;

  /// Free-text notes the user can add to the organized mind map, one per
  /// period tab ('day' | 'week' | 'month').
  Map<String, String> mindMapNotes;

  /// Short colorful sticky notes pinned onto the mind map, several per
  /// period tab — a lighter, more visual complement to the single
  /// paragraph note above.
  Map<String, List<MindMapStickyNote>> mindMapStickyNotes;

  /// Which content shows in the Android home-screen widget.
  bool widgetShowHabits;
  bool widgetShowPriorities;
  bool widgetShowMantra;

  /// Which specific habits appear in the widget's checklist — empty means
  /// "all of them" (the widget itself still caps at 5 for space). Lets
  /// someone with a long habit list pick just the ones they want glanceable
  /// on the home screen instead of always getting the first five.
  List<String> widgetHabitIds;

  /// Whether the one-time "swipe for more" hint on the home screen has
  /// already been shown.
  bool hasSeenSwipeHint;

  /// Finance & Money's Goal Roadmap tool (dream goal → monthly milestones)
  /// and the last income entered into the budget calculator — null/none
  /// until the user sets one up. The split defaults to the classic 50/30/20
  /// but the user can drag it to whatever they like, adding up to 100.
  FinanceRoadmap? financeRoadmap;
  double? financeBudgetIncome;
  double financeBudgetNeedsPct;
  double financeBudgetWantsPct;
  double financeBudgetSavingsPct;

  /// Mindset & Growth tools: user-written reframe pairs (supplementing the
  /// built-in reference list), and per-day logs for the Stress Bucket and
  /// Daily DOSE checklists, keyed by `dayKey` date string.
  List<Reframe> customReframes;
  Map<String, List<String>> stressBucketFills;
  Map<String, List<String>> stressBucketEmpties;
  Map<String, List<String>> doseByDay;

  AppState({
    required this.tasksByDay,
    required this.habits,
    required this.reminders,
    this.keyDates = const [],
    required this.mantraSeed,
    required this.themeMode,
    this.themeAccentId = 'gold',
    this.fontFamilyId = 'inter',
    this.fontScaleId = 'default',
    this.defaultPageKey = 'productivity',
    this.exerciseBellIntervalSeconds = 60,
    List<SpendCategory>? spendCategories,
    this.spendEntries = const [],
    this.sharedBoardCode,
    this.sharedBoardTitle,
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
    this.visionBoardLayoutName,
    required this.financeGoals,
    required this.healthGoals,
    required this.mindsetGoals,
    required this.relationshipsGoals,
    required this.mindMapNotes,
    Map<String, List<MindMapStickyNote>>? mindMapStickyNotes,
    required this.widgetShowHabits,
    required this.widgetShowPriorities,
    required this.widgetShowMantra,
    required this.widgetHabitIds,
    required this.hasSeenSwipeHint,
    this.financeRoadmap,
    this.financeBudgetIncome,
    this.financeBudgetNeedsPct = 50,
    this.financeBudgetWantsPct = 30,
    this.financeBudgetSavingsPct = 20,
    required this.customReframes,
    required this.stressBucketFills,
    required this.stressBucketEmpties,
    required this.doseByDay,
  })  : mindMapStickyNotes = mindMapStickyNotes ?? <String, List<MindMapStickyNote>>{},
        spendCategories = spendCategories ?? defaultSpendCategories();

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
        visionBoardLayoutName: null,
        financeGoals: <Task>[],
        healthGoals: <Task>[],
        mindsetGoals: <Task>[],
        relationshipsGoals: <Task>[],
        mindMapNotes: <String, String>{},
        widgetShowHabits: true,
        widgetShowPriorities: true,
        widgetShowMantra: true,
        widgetHabitIds: <String>[],
        hasSeenSwipeHint: false,
        financeRoadmap: null,
        financeBudgetIncome: null,
        customReframes: <Reframe>[],
        stressBucketFills: <String, List<String>>{},
        stressBucketEmpties: <String, List<String>>{},
        doseByDay: <String, List<String>>{},
      );

  Map<String, dynamic> toJson() => {
        'tasksByDay': tasksByDay.map((key, value) =>
            MapEntry(key, value.map((t) => t.toJson()).toList())),
        'habits': habits.map((h) => h.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'keyDates': keyDates.map((k) => k.toJson()).toList(),
        'mantraSeed': mantraSeed,
        'themeMode': themeMode,
        'themeAccentId': themeAccentId,
        'fontFamilyId': fontFamilyId,
        'fontScaleId': fontScaleId,
        'defaultPageKey': defaultPageKey,
        'exerciseBellIntervalSeconds': exerciseBellIntervalSeconds,
        'spendCategories': spendCategories.map((c) => c.toJson()).toList(),
        'spendEntries': spendEntries.map((e) => e.toJson()).toList(),
        'sharedBoardCode': sharedBoardCode,
        'sharedBoardTitle': sharedBoardTitle,
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
        'visionBoardLayoutName': visionBoardLayoutName,
        'financeGoals': financeGoals.map((t) => t.toJson()).toList(),
        'healthGoals': healthGoals.map((t) => t.toJson()).toList(),
        'mindsetGoals': mindsetGoals.map((t) => t.toJson()).toList(),
        'relationshipsGoals': relationshipsGoals.map((t) => t.toJson()).toList(),
        'mindMapNotes': mindMapNotes,
        'mindMapStickyNotes': mindMapStickyNotes.map(
            (key, value) => MapEntry(key, value.map((n) => n.toJson()).toList())),
        'widgetShowHabits': widgetShowHabits,
        'widgetShowPriorities': widgetShowPriorities,
        'widgetShowMantra': widgetShowMantra,
        'widgetHabitIds': widgetHabitIds,
        'hasSeenSwipeHint': hasSeenSwipeHint,
        'financeRoadmap': financeRoadmap?.toJson(),
        'financeBudgetIncome': financeBudgetIncome,
        'financeBudgetNeedsPct': financeBudgetNeedsPct,
        'financeBudgetWantsPct': financeBudgetWantsPct,
        'financeBudgetSavingsPct': financeBudgetSavingsPct,
        'customReframes': customReframes.map((r) => r.toJson()).toList(),
        'stressBucketFills': stressBucketFills,
        'stressBucketEmpties': stressBucketEmpties,
        'doseByDay': doseByDay,
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
        final enabled = entry['enabled'];
        if (enabled is bool) reminder.enabled = enabled;
        final hour = entry['hour'];
        if (hour is int) reminder.hour = hour;
        final minute = entry['minute'];
        if (minute is int) reminder.minute = minute;
      }
    }

    final rawKeyDates = json['keyDates'];
    if (rawKeyDates is List) {
      state.keyDates = rawKeyDates
          .whereType<Map<String, dynamic>>()
          .map(KeyDate.fromJson)
          .whereType<KeyDate>()
          .toList();
    }

    if (json['mantraSeed'] is int) state.mantraSeed = json['mantraSeed'] as int;
    if (json['themeMode'] is String) {
      state.themeMode = json['themeMode'] as String;
    }
    if (json['themeAccentId'] is String &&
        kAccentPalettes.any((p) => p.id == json['themeAccentId'])) {
      state.themeAccentId = json['themeAccentId'] as String;
    }
    if (json['fontFamilyId'] is String &&
        kFontFamilies.any((f) => f.id == json['fontFamilyId'])) {
      state.fontFamilyId = json['fontFamilyId'] as String;
    }
    if (json['fontScaleId'] is String &&
        kFontScales.any((s) => s.id == json['fontScaleId'])) {
      state.fontScaleId = json['fontScaleId'] as String;
    }
    if (json['defaultPageKey'] is String &&
        kHomePageSections.any((s) => s.key == json['defaultPageKey'])) {
      state.defaultPageKey = json['defaultPageKey'] as String;
    }
    final rawInterval = json['exerciseBellIntervalSeconds'];
    if (rawInterval is int && rawInterval > 0) {
      state.exerciseBellIntervalSeconds = rawInterval;
    }
    final rawSpendCategories = json['spendCategories'];
    if (rawSpendCategories is List) {
      final parsed = rawSpendCategories
          .whereType<Map<String, dynamic>>()
          .map(SpendCategory.fromJson)
          .whereType<SpendCategory>()
          .toList();
      if (parsed.isNotEmpty) state.spendCategories = parsed;
    }
    final rawSpendEntries = json['spendEntries'];
    if (rawSpendEntries is List) {
      state.spendEntries = rawSpendEntries
          .whereType<Map<String, dynamic>>()
          .map(SpendEntry.fromJson)
          .whereType<SpendEntry>()
          .toList();
    }
    if (json['sharedBoardCode'] is String) {
      state.sharedBoardCode = json['sharedBoardCode'] as String;
    }
    if (json['sharedBoardTitle'] is String) {
      state.sharedBoardTitle = json['sharedBoardTitle'] as String;
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
    if (json['visionBoardLayoutName'] is String) {
      state.visionBoardLayoutName = json['visionBoardLayoutName'] as String;
    }

    final rawFinance = json['financeGoals'];
    if (rawFinance is List) {
      state.financeGoals =
          rawFinance.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    final rawHealth = json['healthGoals'];
    if (rawHealth is List) {
      state.healthGoals =
          rawHealth.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    final rawMindset = json['mindsetGoals'];
    if (rawMindset is List) {
      state.mindsetGoals =
          rawMindset.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    final rawRelationships = json['relationshipsGoals'];
    if (rawRelationships is List) {
      state.relationshipsGoals =
          rawRelationships.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
    }
    final rawMindMap = json['mindMapNotes'];
    if (rawMindMap is Map) {
      state.mindMapNotes = rawMindMap.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    final rawSticky = json['mindMapStickyNotes'];
    if (rawSticky is Map) {
      state.mindMapStickyNotes = rawSticky.map((k, v) {
        final notes = v is List
            ? v
                .whereType<Map<String, dynamic>>()
                .map(MindMapStickyNote.fromJson)
                .whereType<MindMapStickyNote>()
                .toList()
            : <MindMapStickyNote>[];
        return MapEntry(k.toString(), notes);
      });
    }
    if (json['widgetShowHabits'] is bool) {
      state.widgetShowHabits = json['widgetShowHabits'] as bool;
    }
    if (json['widgetShowPriorities'] is bool) {
      state.widgetShowPriorities = json['widgetShowPriorities'] as bool;
    }
    if (json['widgetShowMantra'] is bool) {
      state.widgetShowMantra = json['widgetShowMantra'] as bool;
    }
    final rawWidgetHabitIds = json['widgetHabitIds'];
    if (rawWidgetHabitIds is List) {
      state.widgetHabitIds = rawWidgetHabitIds.map((e) => e.toString()).toList();
    }
    if (json['hasSeenSwipeHint'] is bool) {
      state.hasSeenSwipeHint = json['hasSeenSwipeHint'] as bool;
    }

    final rawRoadmap = json['financeRoadmap'];
    if (rawRoadmap is Map<String, dynamic>) {
      state.financeRoadmap = FinanceRoadmap.fromJson(rawRoadmap);
    }
    if (json['financeBudgetIncome'] is num) {
      state.financeBudgetIncome = (json['financeBudgetIncome'] as num).toDouble();
    }
    if (json['financeBudgetNeedsPct'] is num) {
      state.financeBudgetNeedsPct = (json['financeBudgetNeedsPct'] as num).toDouble();
    }
    if (json['financeBudgetWantsPct'] is num) {
      state.financeBudgetWantsPct = (json['financeBudgetWantsPct'] as num).toDouble();
    }
    if (json['financeBudgetSavingsPct'] is num) {
      state.financeBudgetSavingsPct = (json['financeBudgetSavingsPct'] as num).toDouble();
    }
    final rawReframes = json['customReframes'];
    if (rawReframes is List) {
      state.customReframes = rawReframes
          .whereType<Map<String, dynamic>>()
          .map(Reframe.fromJson)
          .toList();
    }
    final rawFills = json['stressBucketFills'];
    if (rawFills is Map) {
      state.stressBucketFills = rawFills.map((k, v) =>
          MapEntry(k.toString(), (v is List) ? v.map((e) => e.toString()).toList() : <String>[]));
    }
    final rawEmpties = json['stressBucketEmpties'];
    if (rawEmpties is Map) {
      state.stressBucketEmpties = rawEmpties.map((k, v) =>
          MapEntry(k.toString(), (v is List) ? v.map((e) => e.toString()).toList() : <String>[]));
    }
    final rawDose = json['doseByDay'];
    if (rawDose is Map) {
      state.doseByDay = rawDose.map((k, v) =>
          MapEntry(k.toString(), (v is List) ? v.map((e) => e.toString()).toList() : <String>[]));
    }

    return state;
  }
}

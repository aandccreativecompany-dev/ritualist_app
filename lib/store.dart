import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mantras.dart';
import 'models.dart';
import 'notifications.dart';
import 'theme.dart' show setAccentId, setFontFamily, setFontScale;
import 'tips.dart';

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
    setAccentId(_state.themeAccentId);
    setFontFamily(_state.fontFamilyId);
    setFontScale(_state.fontScaleId);
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

  /// Swaps in a whole different AppState — used when a cloud backup is
  /// pulled down after signing in — and immediately persists + notifies,
  /// same as any other write.
  Future<void> replaceState(AppState newState) async {
    _state = newState;
    await _commit();
    await rescheduleReminders();
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
    list.insert(0, Task(title: trimmed));
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

  /// Toggle a habit's completion for any calendar day, not just today — for
  /// the tappable habit calendar (users can back-fill or correct any date).
  Future<void> toggleHabitOn(Habit habit, DateTime date) async {
    final target = _findHabit(habit.id) ?? habit;
    target.toggle(date);
    await _commit();
  }

  Future<void> addHabit(String name, {int? iconIndex, int? colorIndex}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _state.habits.add(Habit(
      name: trimmed,
      iconIndex: iconIndex ?? 0,
      colorIndex: colorIndex ?? _state.habits.length,
    ));
    await _commit();
  }

  /// Looked up by id rather than trusting the caller's object reference —
  /// keeps add/remove/edit correct even if a widget is holding a stale
  /// instance from a previous rebuild.
  Habit? _findHabit(String id) {
    for (final h in _state.habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<void> removeHabit(Habit habit) async {
    _state.habits.removeWhere((h) => h.id == habit.id);
    await _commit();
  }

  Future<void> renameHabit(Habit habit, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final target = _findHabit(habit.id) ?? habit;
    target.name = trimmed;
    await _commit();
  }

  Future<void> setHabitStyle(Habit habit, {int? iconIndex, int? colorIndex}) async {
    final target = _findHabit(habit.id) ?? habit;
    if (iconIndex != null) target.iconIndex = iconIndex;
    if (colorIndex != null) target.colorIndex = colorIndex;
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

  // ---- Productivity tip ----

  String get tipOfTheDay {
    final dayNumber = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    final index = (dayNumber + _state.mantraSeed) % productivityTips.length;
    return productivityTips[index.abs()];
  }

  // ---- Mood check-in / evening prompt ----

  String? get todaysMood => _state.moodByDay[dayKey(DateTime.now())];

  bool get shouldShowMoodPrompt =>
      onboardingComplete &&
      _state.lastMoodPromptDay != dayKey(DateTime.now());

  Future<void> recordMoodPromptShown() async {
    _state.lastMoodPromptDay = dayKey(DateTime.now());
    await _commit();
  }

  Future<void> setTodaysMood(String mood) async {
    _state.moodByDay[dayKey(DateTime.now())] = mood;
    await recordMoodPromptShown();
  }

  bool get shouldShowEveningPrompt =>
      onboardingComplete &&
      DateTime.now().hour >= 19 &&
      _state.lastEveningPromptDay != dayKey(DateTime.now());

  Future<void> recordEveningPromptShown() async {
    _state.lastEveningPromptDay = dayKey(DateTime.now());
    await _commit();
  }

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

  /// Which accent palette (theme.dart's kAccentPalettes) is active.
  String get themeAccentId => _state.themeAccentId;

  Future<void> setThemeAccent(String id) async {
    _state.themeAccentId = id;
    setAccentId(id);
    await _commit();
  }

  /// Which reading font (theme.dart's kFontFamilies) is active for body text.
  String get fontFamilyId => _state.fontFamilyId;

  Future<void> setFontFamilyChoice(String id) async {
    _state.fontFamilyId = id;
    setFontFamily(id);
    await _commit();
  }

  /// Which text size scale (theme.dart's kFontScales) is active.
  String get fontScaleId => _state.fontScaleId;

  Future<void> setFontScaleChoice(String id) async {
    _state.fontScaleId = id;
    setFontScale(id);
    await _commit();
  }

  /// Which kHomePageSections key opens first on launch.
  String get defaultPageKey => _state.defaultPageKey;

  Future<void> setDefaultPage(String key) async {
    _state.defaultPageKey = key;
    await _commit();
  }

  /// Chosen interval (seconds) for the exercise interval bell timer.
  int get exerciseBellIntervalSeconds => _state.exerciseBellIntervalSeconds;

  Future<void> setExerciseBellInterval(int seconds) async {
    if (seconds <= 0) return;
    _state.exerciseBellIntervalSeconds = seconds;
    await _commit();
  }

  // ---- Wallet / spending tracker ----

  List<SpendCategory> get spendCategories => _state.spendCategories;
  List<SpendEntry> get spendEntries => _state.spendEntries;

  Future<void> addSpendCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _state.spendCategories.add(
        SpendCategory(id: '${DateTime.now().microsecondsSinceEpoch}', name: trimmed));
    await _commit();
  }

  Future<void> renameSpendCategory(SpendCategory category, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    category.name = trimmed;
    await _commit();
  }

  Future<void> removeSpendCategory(SpendCategory category) async {
    // Also drops any logged entries pointing at it, so the tracker never
    // ends up showing an expense under a category that no longer exists.
    _state.spendCategories.remove(category);
    _state.spendEntries.removeWhere((e) => e.categoryId == category.id);
    await _commit();
  }

  Future<void> addSpendSubcategory(SpendCategory category, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || category.subcategories.contains(trimmed)) return;
    category.subcategories.add(trimmed);
    await _commit();
  }

  Future<void> removeSpendSubcategory(SpendCategory category, String name) async {
    category.subcategories.remove(name);
    await _commit();
  }

  Future<void> addSpendEntry({
    required String categoryId,
    String subcategory = '',
    required double amount,
    required bool isNeed,
    String note = '',
  }) async {
    if (amount <= 0) return;
    _state.spendEntries.insert(
      0,
      SpendEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        categoryId: categoryId,
        subcategory: subcategory.trim(),
        amount: amount,
        isNeed: isNeed,
        note: note.trim(),
        date: DateTime.now(),
      ),
    );
    await _commit();
  }

  Future<void> removeSpendEntry(SpendEntry entry) async {
    _state.spendEntries.remove(entry);
    await _commit();
  }

  SpendCategory? spendCategoryById(String id) {
    for (final c in _state.spendCategories) {
      if (c.id == id) return c;
    }
    return null;
  }

  double get totalSpent =>
      _state.spendEntries.fold(0.0, (sum, e) => sum + e.amount);
  double get totalNeedSpent =>
      _state.spendEntries.where((e) => e.isNeed).fold(0.0, (sum, e) => sum + e.amount);
  double get totalWantSpent =>
      _state.spendEntries.where((e) => !e.isNeed).fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get spentByCategoryId {
    final result = <String, double>{};
    for (final e in _state.spendEntries) {
      result[e.categoryId] = (result[e.categoryId] ?? 0) + e.amount;
    }
    return result;
  }

  // ---- Shared vision board (cached locally so the code isn't re-entered) ----

  String? get sharedBoardCode => _state.sharedBoardCode;
  String? get sharedBoardTitle => _state.sharedBoardTitle;

  Future<void> setSharedBoard(String? code, String? title) async {
    _state.sharedBoardCode = code;
    _state.sharedBoardTitle = title;
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
      keyDates: _state.keyDates,
      mantra: mantraOfTheDay,
      openTasks: todaysTasks.where((t) => !t.done).map((t) => t.title).toList(),
    );
  }

  // ---- Key dates (yearly reminders) ----

  List<KeyDate> get keyDates => _state.keyDates;

  Future<void> addKeyDate(String title, int month, int day) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.keyDates.add(KeyDate(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: trimmed,
      month: month,
      day: day,
    ));
    await _commit();
    await rescheduleReminders();
  }

  Future<void> removeKeyDate(KeyDate keyDate) async {
    _state.keyDates.remove(keyDate);
    await _commit();
    await rescheduleReminders();
  }

  // ---- Onboarding ----

  bool get onboardingComplete => _state.onboardingComplete;

  String get userName => _state.userName;

  String get dailyTimeCommitment => _state.dailyTimeCommitment;

  List<String> get focusAreas => _state.focusAreas;

  Future<void> completeOnboarding({
    required String userName,
    required List<String> focusAreas,
    required String dailyTimeCommitment,
    required String preset,
  }) async {
    _state.onboardingComplete = true;
    _state.userName = userName.trim();
    _state.focusAreas = focusAreas;
    _state.dailyTimeCommitment = dailyTimeCommitment;
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

  // ---- Journaling (Brain Dump) — manifestation scripts + free brain dumps ----

  List<Script> get scripts => _state.scripts;

  Future<void> addScript(String title, String body, {String mode = 'manifest'}) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;
    _state.scripts
        .insert(0, Script(title: title.trim(), body: body.trim(), mode: mode));
    await _commit();
  }

  Future<void> updateScript(Script script, String title, String body,
      {String? mode}) async {
    script.title = title.trim();
    script.body = body.trim();
    if (mode != null) script.mode = mode;
    await _commit();
  }

  Future<void> removeScript(Script script) async {
    _state.scripts.remove(script);
    await _commit();
  }

  // ---- Finance & Money tools: Goal Roadmap + 50/30/20 budget calculator ----

  FinanceRoadmap? get financeRoadmap => _state.financeRoadmap;

  Future<void> setFinanceRoadmap(String dreamGoal, double targetAmount, int months) async {
    _state.financeRoadmap =
        FinanceRoadmap(dreamGoal: dreamGoal.trim(), targetAmount: targetAmount, months: months);
    await _commit();
  }

  Future<void> toggleRoadmapMonth(int index) async {
    final roadmap = _state.financeRoadmap;
    if (roadmap == null || index < 0 || index >= roadmap.monthsDone.length) return;
    roadmap.monthsDone[index] = !roadmap.monthsDone[index];
    await _commit();
  }

  Future<void> clearFinanceRoadmap() async {
    _state.financeRoadmap = null;
    await _commit();
  }

  double? get financeBudgetIncome => _state.financeBudgetIncome;

  Future<void> setFinanceBudgetIncome(double income) async {
    _state.financeBudgetIncome = income;
    await _commit();
  }

  double get financeBudgetNeedsPct => _state.financeBudgetNeedsPct;
  double get financeBudgetWantsPct => _state.financeBudgetWantsPct;
  double get financeBudgetSavingsPct => _state.financeBudgetSavingsPct;

  /// Sets all three budget split percentages at once — callers are
  /// responsible for keeping them summing to ~100, which the slider UI does
  /// by redistributing the other two whenever one moves.
  Future<void> setFinanceBudgetSplit(double needs, double wants, double savings) async {
    _state.financeBudgetNeedsPct = needs;
    _state.financeBudgetWantsPct = wants;
    _state.financeBudgetSavingsPct = savings;
    await _commit();
  }

  Future<void> resetFinanceBudgetSplit() async {
    _state.financeBudgetNeedsPct = 50;
    _state.financeBudgetWantsPct = 30;
    _state.financeBudgetSavingsPct = 20;
    await _commit();
  }

  // ---- Mindset & Growth tools ----

  List<Reframe> get customReframes => _state.customReframes;

  Future<void> addCustomReframe(String negative, String positive) async {
    if (negative.trim().isEmpty || positive.trim().isEmpty) return;
    _state.customReframes.add(Reframe(negative: negative.trim(), positive: positive.trim()));
    await _commit();
  }

  Future<void> removeCustomReframe(int index) async {
    if (index < 0 || index >= _state.customReframes.length) return;
    _state.customReframes.removeAt(index);
    await _commit();
  }

  List<String> get todaysStressFills =>
      _state.stressBucketFills[dayKey(DateTime.now())] ?? <String>[];
  List<String> get todaysStressEmpties =>
      _state.stressBucketEmpties[dayKey(DateTime.now())] ?? <String>[];

  Future<void> toggleStressFill(String item) async {
    final key = dayKey(DateTime.now());
    final list = _state.stressBucketFills.putIfAbsent(key, () => <String>[]);
    if (!list.remove(item)) list.add(item);
    await _commit();
  }

  Future<void> toggleStressEmpty(String item) async {
    final key = dayKey(DateTime.now());
    final list = _state.stressBucketEmpties.putIfAbsent(key, () => <String>[]);
    if (!list.remove(item)) list.add(item);
    await _commit();
  }

  List<String> get todaysDose => _state.doseByDay[dayKey(DateTime.now())] ?? <String>[];

  Future<void> toggleDoseActivity(String activity) async {
    final key = dayKey(DateTime.now());
    final list = _state.doseByDay.putIfAbsent(key, () => <String>[]);
    if (!list.remove(activity)) list.add(activity);
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

  /// Updates one tile's own shape/size/image framing — the per-tile
  /// customization that replaced the old board-wide-only shape setting.
  Future<void> updateVisionItemStyle(
    VisionItem item, {
    String? shape,
    int? spanX,
    int? spanY,
    double? imageOffsetX,
    double? imageOffsetY,
    double? imageZoom,
  }) async {
    if (shape != null) item.shape = shape;
    if (spanX != null) item.spanX = spanX.clamp(1, 2);
    if (spanY != null) item.spanY = spanY.clamp(1, 2);
    if (imageOffsetX != null) item.imageOffsetX = imageOffsetX.clamp(0.0, 1.0);
    if (imageOffsetY != null) item.imageOffsetY = imageOffsetY.clamp(0.0, 1.0);
    if (imageZoom != null) item.imageZoom = imageZoom.clamp(1.0, 2.5);
    await _commit();
  }

  /// Applies a curated layout's shape/size recipe to the existing tiles, in
  /// order, cycling the recipe if there are more tiles than slots.
  Future<void> applyVisionLayout(VisionLayoutSpec layout) async {
    if (_state.visionItems.isEmpty || layout.slots.isEmpty) return;
    for (var i = 0; i < _state.visionItems.length; i++) {
      final slot = layout.slots[i % layout.slots.length];
      _state.visionItems[i].shape = slot.$1;
      _state.visionItems[i].spanX = slot.$2;
      _state.visionItems[i].spanY = slot.$3;
    }
    _state.visionBoardLayoutName = layout.name;
    await _commit();
  }

  String? get visionBoardLayoutName => _state.visionBoardLayoutName;

  // ---- Weekly / monthly goals ----

  List<Task> get weeklyGoals => _state.weeklyGoals;
  List<Task> get monthlyGoals => _state.monthlyGoals;

  Future<void> addWeeklyGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.weeklyGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleWeeklyGoal(int index) async {
    if (index < 0 || index >= _state.weeklyGoals.length) return;
    _state.weeklyGoals[index].done = !_state.weeklyGoals[index].done;
    await _commit();
  }

  Future<void> removeWeeklyGoal(int index) async {
    if (index < 0 || index >= _state.weeklyGoals.length) return;
    _state.weeklyGoals.removeAt(index);
    await _commit();
  }

  Future<void> addMonthlyGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.monthlyGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleMonthlyGoal(int index) async {
    if (index < 0 || index >= _state.monthlyGoals.length) return;
    _state.monthlyGoals[index].done = !_state.monthlyGoals[index].done;
    await _commit();
  }

  Future<void> removeMonthlyGoal(int index) async {
    if (index < 0 || index >= _state.monthlyGoals.length) return;
    _state.monthlyGoals.removeAt(index);
    await _commit();
  }

  // ---- Finance & Money goals / Health & Body goals ----

  List<Task> get financeGoals => _state.financeGoals;
  List<Task> get healthGoals => _state.healthGoals;

  Future<void> addFinanceGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.financeGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleFinanceGoal(int index) async {
    if (index < 0 || index >= _state.financeGoals.length) return;
    _state.financeGoals[index].done = !_state.financeGoals[index].done;
    await _commit();
  }

  Future<void> removeFinanceGoal(int index) async {
    if (index < 0 || index >= _state.financeGoals.length) return;
    _state.financeGoals.removeAt(index);
    await _commit();
  }

  Future<void> addHealthGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.healthGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleHealthGoal(int index) async {
    if (index < 0 || index >= _state.healthGoals.length) return;
    _state.healthGoals[index].done = !_state.healthGoals[index].done;
    await _commit();
  }

  Future<void> removeHealthGoal(int index) async {
    if (index < 0 || index >= _state.healthGoals.length) return;
    _state.healthGoals.removeAt(index);
    await _commit();
  }

  // ---- Mindset & Growth / Relationships & Connection goals ----

  List<Task> get mindsetGoals => _state.mindsetGoals;
  List<Task> get relationshipsGoals => _state.relationshipsGoals;

  Future<void> addMindsetGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.mindsetGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleMindsetGoal(int index) async {
    if (index < 0 || index >= _state.mindsetGoals.length) return;
    _state.mindsetGoals[index].done = !_state.mindsetGoals[index].done;
    await _commit();
  }

  Future<void> removeMindsetGoal(int index) async {
    if (index < 0 || index >= _state.mindsetGoals.length) return;
    _state.mindsetGoals.removeAt(index);
    await _commit();
  }

  Future<void> addRelationshipsGoal(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _state.relationshipsGoals.insert(0, Task(title: trimmed));
    await _commit();
  }

  Future<void> toggleRelationshipsGoal(int index) async {
    if (index < 0 || index >= _state.relationshipsGoals.length) return;
    _state.relationshipsGoals[index].done = !_state.relationshipsGoals[index].done;
    await _commit();
  }

  Future<void> removeRelationshipsGoal(int index) async {
    if (index < 0 || index >= _state.relationshipsGoals.length) return;
    _state.relationshipsGoals.removeAt(index);
    await _commit();
  }

  // ---- Organized mind map ----

  /// Auto-computed performance snapshot for 'day' | 'week' | 'month'.
  ({int habitsDone, int habitsTotal, int prioritiesDone, int prioritiesTotal,
      String? mood, bool journaled, int scriptsCount})
      mindMapSnapshot(String period) {
    final today = DateTime.now();
    final days = period == 'day' ? 1 : (period == 'week' ? 7 : 30);
    var prioritiesDone = 0, prioritiesTotal = 0, habitsDone = 0;
    String? lastMood;
    var journaled = false;
    for (var i = 0; i < days; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final tasks = tasksFor(day);
      prioritiesTotal += tasks.length;
      prioritiesDone += tasks.where((t) => t.done).length;
      for (final habit in _state.habits) {
        if (habit.isDoneOn(day)) habitsDone++;
      }
      if (i == 0) {
        lastMood = _state.moodByDay[dayKey(day)];
        journaled = !journalFor(day).isEmpty;
      }
    }
    return (
      habitsDone: habitsDone,
      habitsTotal: _state.habits.length * days,
      prioritiesDone: prioritiesDone,
      prioritiesTotal: prioritiesTotal,
      mood: lastMood,
      journaled: journaled,
      scriptsCount: _state.scripts.length,
    );
  }

  String mindMapNoteFor(String period) => _state.mindMapNotes[period] ?? '';

  Future<void> setMindMapNote(String period, String text) async {
    if (text.trim().isEmpty) {
      _state.mindMapNotes.remove(period);
    } else {
      _state.mindMapNotes[period] = text;
    }
    await _commit();
  }

  List<MindMapStickyNote> mindMapStickyNotesFor(String period) =>
      _state.mindMapStickyNotes[period] ?? const [];

  Future<void> addMindMapStickyNote(String period, String text, int colorIndex) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = _state.mindMapStickyNotes.putIfAbsent(period, () => []);
    list.add(MindMapStickyNote(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      colorIndex: colorIndex,
    ));
    await _commit();
  }

  Future<void> removeMindMapStickyNote(String period, MindMapStickyNote note) async {
    _state.mindMapStickyNotes[period]?.remove(note);
    await _commit();
  }

  // ---- Home screen widget preferences ----

  bool get widgetShowHabits => _state.widgetShowHabits;
  bool get widgetShowPriorities => _state.widgetShowPriorities;
  bool get widgetShowMantra => _state.widgetShowMantra;

  Future<void> setWidgetShowHabits(bool value) async {
    _state.widgetShowHabits = value;
    await _commit();
  }

  Future<void> setWidgetShowPriorities(bool value) async {
    _state.widgetShowPriorities = value;
    await _commit();
  }

  Future<void> setWidgetShowMantra(bool value) async {
    _state.widgetShowMantra = value;
    await _commit();
  }

  /// Empty means "all habits" — the widget itself still caps at 5 for
  /// space, but this lets someone with a longer list choose which ones.
  List<String> get widgetHabitIds => _state.widgetHabitIds;

  Future<void> toggleWidgetHabit(String habitId) async {
    if (_state.widgetHabitIds.contains(habitId)) {
      _state.widgetHabitIds.remove(habitId);
    } else {
      _state.widgetHabitIds.add(habitId);
    }
    await _commit();
  }

  bool widgetHabitSelected(String habitId) =>
      _state.widgetHabitIds.isEmpty || _state.widgetHabitIds.contains(habitId);

  // ---- Home screen swipe hint ----

  bool get hasSeenSwipeHint => _state.hasSeenSwipeHint;

  Future<void> markSwipeHintSeen() async {
    if (_state.hasSeenSwipeHint) return;
    _state.hasSeenSwipeHint = true;
    await _commit();
  }

  // ---- Avatar / vision board shape ----

  String get avatarGender => _state.avatarGender;

  Future<void> setAvatarGender(String value) async {
    _state.avatarGender = value;
    await _commit();
  }

  String get visionBoardShape => _state.visionBoardShape;

  Future<void> setVisionBoardShape(String value) async {
    if (!kVisionShapes.contains(value)) return;
    _state.visionBoardShape = value;
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

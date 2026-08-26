import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../store.dart';

/// Keeps the Android home-screen widget's data in sync with the store.
/// Content shown is user-selectable in Settings (habits checklist, top
/// to-do/priority, today's mantra) — all three by default. The widget's
/// own native provider/layout live in `android_overrides/widget/` and are
/// copied into the freshly-generated Android project by CI, the same way
/// `google-services.json` is.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  static const _androidWidgetName = 'HabitsWidgetProvider';

  bool _wired = false;

  /// Starts listening to the store and pushing widget data on every change.
  /// Safe to call more than once — only wires the listener the first time.
  void wire() {
    if (_wired) return;
    _wired = true;
    store.addListener(_push);
    _push();
  }

  Future<void> _push() async {
    try {
      if (store.widgetShowHabits) {
        final today = DateTime.now();
        final habitsJson = jsonEncode([
          for (final h in store.habits.take(5))
            {'name': h.name, 'done': h.isDoneOn(today)},
        ]);
        await HomeWidget.saveWidgetData<String>('widget_habits', habitsJson);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_habits', '[]');
      }

      if (store.widgetShowPriorities) {
        final open = store.todaysTasks.where((t) => !t.done).toList();
        await HomeWidget.saveWidgetData<String>(
            'widget_top_priority', open.isEmpty ? '' : open.first.title);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_top_priority', '');
      }

      if (store.widgetShowMantra) {
        await HomeWidget.saveWidgetData<String>(
            'widget_mantra', store.mantraOfTheDay);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_mantra', '');
      }

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {
      // No widget added yet, or running on a platform without the native
      // provider (iOS isn't wired up) — nothing else in the app depends on
      // this succeeding.
    }
  }
}

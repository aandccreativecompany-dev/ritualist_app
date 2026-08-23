import 'package:flutter/material.dart';

import '../models.dart';
import '../notifications.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await Notifications.instance.permissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _enable(ReminderSetting reminder, bool value) async {
    if (value && !_permissionGranted) {
      final granted = await Notifications.instance.requestPermission();
      if (mounted) setState(() => _permissionGranted = granted);
      if (!granted) return;
    }
    await store.setReminderEnabled(reminder, value);
  }

  Future<void> _pickTime(ReminderSetting reminder) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked != null) {
      await store.setReminderTime(reminder, picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back,
                            color: Surfaces.bodyText(dark)),
                      ),
                      Text('Reminders',
                          style: body(14, Surfaces.heading(dark),
                              weight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Nudges for the busy hours',
                      style: display(23, Surfaces.heading(dark))),
                  const SizedBox(height: 8),
                  Text(
                      "Ritualist reaches out so you don't have to remember to open it.",
                      style: body(12.5, Surfaces.muted(dark))),
                  const SizedBox(height: 22),
                  if (!_permissionGranted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ModuleCard(
                        accent: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notifications are switched off',
                                style: body(13.5, Surfaces.accentText(dark),
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                                'Ritualist needs permission before it can send reminders.',
                                style: body(12.5, Surfaces.bodyText(dark))),
                            const SizedBox(height: 14),
                            GoldButton(
                              labelText: 'Allow notifications',
                              onPressed: () async {
                                final granted = await Notifications.instance
                                    .requestPermission();
                                if (mounted) {
                                  setState(() => _permissionGranted = granted);
                                }
                                await store.rescheduleReminders();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final reminder in store.reminders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ModuleCard(
                        accent: reminder.enabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(reminder.title,
                                          style: body(14,
                                              Surfaces.heading(dark),
                                              weight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(_subtitleFor(reminder.id),
                                          style: body(11.5,
                                              Surfaces.muted(dark))),
                                    ],
                                  ),
                                ),
                                BrandSwitch(
                                  value: reminder.enabled,
                                  onChanged: (value) =>
                                      _enable(reminder, value),
                                ),
                              ],
                            ),
                            if (reminder.enabled) ...[
                              const SizedBox(height: 14),
                              Divider(
                                  height: 1,
                                  color: Surfaces.accentBorder(dark)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _pickTime(reminder),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Time',
                                          style: body(13,
                                              Surfaces.bodyText(dark),
                                              weight: FontWeight.w500)),
                                      Text(reminder.clockLabel,
                                          style: display(
                                              15, Surfaces.accent(dark))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('QUIET HOURS', style: label(Surfaces.muted(dark))),
                  const SizedBox(height: 12),
                  ModuleCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Skip on weekends',
                              style: body(13.5, Surfaces.bodyText(dark),
                                  weight: FontWeight.w500)),
                        ),
                        BrandSwitch(
                          value: store.state.skipWeekends,
                          onChanged: (value) => store.setSkipWeekends(value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _subtitleFor(String id) {
    switch (id) {
      case 'mantra':
        return 'Sent with your top 3 priorities';
      case 'midday':
        return 'Only if something is still open';
      default:
        return 'Habits and tomorrow';
    }
  }
}

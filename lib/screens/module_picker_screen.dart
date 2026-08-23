import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// The drag-to-reorder, toggle-to-hide list of home-screen cards. Used both
/// during onboarding (step 3 of the quiz) and standalone from Settings, where
/// it's retakeable at any time.
class ModulePickerBody extends StatelessWidget {
  const ModulePickerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final modules = store.modules;
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          onReorder: (oldIndex, newIndex) =>
              store.reorderModule(oldIndex, newIndex),
          itemBuilder: (context, i) {
            final module = modules[i];
            return Container(
              key: ValueKey(module.id),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Surfaces.card(dark),
                border: Border.all(color: Surfaces.cardBorder(dark)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, color: Surfaces.muted(dark), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kModuleTitles[module.id] ?? module.id,
                      style: body(14, Surfaces.heading(dark), weight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: module.enabled,
                    activeTrackColor: Surfaces.accent(dark),
                    onChanged: (v) => store.setModuleEnabled(module.id, v),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ModulePickerScreen extends StatelessWidget {
  const ModulePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                    icon: Icon(Icons.arrow_back, color: Surfaces.bodyText(dark)),
                  ),
                  Expanded(
                    child: Text('Your daily cards',
                        style: body(14, Surfaces.heading(dark), weight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Drag to reorder, switch off what you don\'t want.',
                  style: body(12.5, Surfaces.muted(dark)),
                ),
              ),
              const SizedBox(height: 18),
              const ModulePickerBody(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Skin Health — was a Skin Care intake form embedded via WebView; the form
/// is removed for now (per product decision) and replaced with a short,
/// practical set of grounded skin-health habits so the section still gives
/// users something actionable. More Personal Care sub-sections (sleep,
/// nutrition, movement) can slot in next to this one later.
class PersonalCareScreen extends StatelessWidget {
  const PersonalCareScreen({super.key});

  static const _tips = [
    (
      Icons.water_drop_outlined,
      'Hydrate first',
      'Skin reflects overall hydration before any product does. Aim for '
          'steady water intake through the day rather than a rushed catch-up '
          'at night.',
    ),
    (
      Icons.wb_sunny_outlined,
      'Protect from sun daily',
      'UV exposure is the single biggest driver of visible skin aging. A '
          'broad-spectrum SPF in the morning matters more than any evening '
          'routine.',
    ),
    (
      Icons.bedtime_outlined,
      'Prioritize sleep',
      'Skin repairs itself overnight. Consistently short sleep shows up as '
          'dullness and slower healing before it shows up anywhere else.',
    ),
    (
      Icons.cleaning_services_outlined,
      'Keep it simple',
      'A gentle cleanser and a moisturizer, used consistently, usually beat '
          'a long list of actives used inconsistently.',
    ),
    (
      Icons.restaurant_outlined,
      'Mind sugar & processed food',
      'Diets high in refined sugar are linked to accelerated skin aging in '
          'multiple studies — small, steady swaps add up more than strict '
          'short-term diets.',
    ),
    (
      Icons.self_improvement_outlined,
      'Manage stress',
      'Chronic stress raises cortisol, which can worsen breakouts and slow '
          'healing. Whatever helps you decompress is part of your skin '
          'routine too.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: FadeSlideIn(
            child: Column(
              children: [
                const ScreenHeader(
                  icon: Icons.spa_outlined,
                  title: 'Skin Health',
                  subtitle: 'Grounded, everyday habits — no forms to fill out.',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      for (final (icon, title, desc) in _tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ModuleCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Surfaces.accent(dark).withValues(alpha: 0.14),
                                  ),
                                  child: Icon(icon, size: 17, color: Surfaces.accent(dark)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: body(14, Surfaces.heading(dark),
                                              weight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(desc,
                                          textAlign: TextAlign.justify,
                                          style: body(12.5, Surfaces.bodyText(dark))
                                              .copyWith(height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

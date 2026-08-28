import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A wallet / spending tracker for the Finance & money section — log an
/// expense against a fully customizable category + sub-category, tag it
/// Need or Want, and see totals split by both.
class SpendingTrackerScreen extends StatelessWidget {
  const SpendingTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entries = store.spendEntries;
        final total = store.totalSpent;
        final needTotal = store.totalNeedSpent;
        final wantTotal = store.totalWantSpent;
        final needPct = total <= 0 ? 0.0 : (needTotal / total * 100).clamp(0, 100);
        final wantPct = total <= 0 ? 0.0 : (wantTotal / total * 100).clamp(0, 100);

        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: FadeSlideIn(
                child: Column(
                  children: [
                    ScreenHeader(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet & spending',
                      subtitle: 'Log what you spend, tagged Need or Want.',
                      actions: [
                        IconButton(
                          tooltip: 'Manage categories',
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const _ManageCategoriesScreen())),
                          icon: Icon(Icons.tune, color: Surfaces.accent(dark)),
                        ),
                        IconButton(
                          tooltip: 'Add expense',
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const _AddSpendScreen())),
                          icon: Icon(Icons.add_circle_outline, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL SPENT', style: label(Surfaces.eyebrow(dark))),
                                const SizedBox(height: 6),
                                Text('₹${total.toStringAsFixed(0)}',
                                    style: display(26, Surfaces.heading(dark))),
                                if (total > 0) ...[
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 12,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: (needPct * 10).round().clamp(1, 1000),
                                            child: Container(color: const Color(0xFF6FDCA8)),
                                          ),
                                          Expanded(
                                            flex: (wantPct * 10).round().clamp(1, 1000),
                                            child: Container(color: const Color(0xFFF08BA0)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _LegendDot(color: const Color(0xFF6FDCA8)),
                                      const SizedBox(width: 6),
                                      Text('Need ₹${needTotal.toStringAsFixed(0)}',
                                          style: body(11.5, Surfaces.muted(dark))),
                                      const SizedBox(width: 16),
                                      _LegendDot(color: const Color(0xFFF08BA0)),
                                      const SizedBox(width: 6),
                                      Text('Want ₹${wantTotal.toStringAsFixed(0)}',
                                          style: body(11.5, Surfaces.muted(dark))),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Nothing logged yet — tap + to add an expense.',
                                    style: body(13, Surfaces.muted(dark))),
                              ),
                            )
                          else
                            for (final entry in entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SpendRow(entry: entry, dark: dark),
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
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _SpendRow extends StatelessWidget {
  final SpendEntry entry;
  final bool dark;
  const _SpendRow({required this.entry, required this.dark});

  @override
  Widget build(BuildContext context) {
    final category = store.spendCategoryById(entry.categoryId);
    final tagColor = entry.isNeed ? const Color(0xFF6FDCA8) : const Color(0xFFF08BA0);
    return ModuleCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Uncategorized',
                  style: body(13.5, Surfaces.heading(dark), weight: FontWeight.w700),
                ),
                if (entry.subcategory.isNotEmpty || entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [entry.subcategory, entry.note].where((s) => s.isNotEmpty).join(' · '),
                    style: body(11.5, Surfaces.muted(dark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: dark ? 0.24 : 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.isNeed ? 'Need' : 'Want',
                      style: body(10, tagColor, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Text('₹${entry.amount.toStringAsFixed(0)}',
              style: display(15, Surfaces.heading(dark))),
          IconButton(
            onPressed: () => store.removeSpendEntry(entry),
            icon: Icon(Icons.close, size: 16, color: Surfaces.muted(dark)),
          ),
        ],
      ),
    );
  }
}

/// Full screen add-expense form — Save is pinned in the AppBar, same
/// keyboard-safe pattern established for the journaling entry screen.
class _AddSpendScreen extends StatefulWidget {
  const _AddSpendScreen();
  @override
  State<_AddSpendScreen> createState() => _AddSpendScreenState();
}

class _AddSpendScreenState extends State<_AddSpendScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newSubCtrl = TextEditingController();
  String? _categoryId;
  String _subcategory = '';
  bool _isNeed = true;

  @override
  void initState() {
    super.initState();
    if (store.spendCategories.isNotEmpty) {
      _categoryId = store.spendCategories.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _newSubCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final categoryId = _categoryId;
    if (amount == null || amount <= 0 || categoryId == null) return;
    await store.addSpendEntry(
      categoryId: categoryId,
      subcategory: _subcategory,
      amount: amount,
      isNeed: _isNeed,
      note: _noteCtrl.text,
    );
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Logged');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final categories = store.spendCategories;
    final selectedCategory =
        categories.where((c) => c.id == _categoryId).toList();
    final subcategories = selectedCategory.isEmpty ? <String>[] : selectedCategory.first.subcategories;

    return Scaffold(
      backgroundColor: dark ? Brand.deep : Brand.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Surfaces.heading(dark)),
        title: Text('Log an expense', style: display(17, Surfaces.heading(dark))),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: Icon(Icons.check_circle, color: Surfaces.accent(dark), size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: body(20, Surfaces.bodyText(dark), weight: FontWeight.w700),
                  decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
                ),
                const SizedBox(height: 18),
                Text('CATEGORY', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  Text('Add a category first from Manage categories.',
                      style: body(12.5, Surfaces.muted(dark)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() {
                            _categoryId = category.id;
                            _subcategory = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _categoryId == category.id
                                  ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _categoryId == category.id
                                    ? Surfaces.accent(dark)
                                    : Surfaces.accentBorder(dark),
                              ),
                            ),
                            child: Text(category.name,
                                style: body(13,
                                    _categoryId == category.id
                                        ? Surfaces.accent(dark)
                                        : Surfaces.bodyText(dark),
                                    weight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                if (subcategories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('SUB-CATEGORY (OPTIONAL)', style: label(Surfaces.eyebrow(dark))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sub in subcategories)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(
                              () => _subcategory = _subcategory == sub ? '' : sub),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _subcategory == sub
                                  ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _subcategory == sub
                                    ? Surfaces.accent(dark)
                                    : Surfaces.accentBorder(dark),
                              ),
                            ),
                            child: Text(sub,
                                style: body(12,
                                    _subcategory == sub
                                        ? Surfaces.accent(dark)
                                        : Surfaces.muted(dark),
                                    weight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Text('NEED OR WANT?', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _NeedWantOption(
                        label: 'Need',
                        color: const Color(0xFF6FDCA8),
                        selected: _isNeed,
                        dark: dark,
                        onTap: () => setState(() => _isNeed = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeedWantOption(
                        label: 'Want',
                        color: const Color(0xFFF08BA0),
                        selected: !_isNeed,
                        dark: dark,
                        onTap: () => setState(() => _isNeed = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('NOTE (OPTIONAL)', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, Surfaces.bodyText(dark)),
                  decoration: const InputDecoration(hintText: 'e.g. Weekend groceries'),
                ),
                const SizedBox(height: 26),
                GoldButton(labelText: 'Save expense', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedWantOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _NeedWantOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: dark ? 0.28 : 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Surfaces.cardBorder(dark), width: selected ? 1.6 : 1),
        ),
        child: Text(label,
            style: body(14, selected ? color : Surfaces.bodyText(dark), weight: FontWeight.w700)),
      ),
    );
  }
}

/// Add/rename/delete category headers and their sub-headers — the
/// "customized values for headers and sub headers" the spending tracker
/// needed. A plain full-screen list, no bottom sheets, kept deliberately
/// simple so there's little surface area for something to go wrong.
class _ManageCategoriesScreen extends StatefulWidget {
  const _ManageCategoriesScreen();
  @override
  State<_ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<_ManageCategoriesScreen> {
  Future<void> _addCategory() async {
    final name = await _promptText(context, 'New category', 'e.g. Health');
    if (name != null && name.trim().isNotEmpty) {
      await store.addSpendCategory(name);
      setState(() {});
    }
  }

  Future<void> _renameCategory(SpendCategory category) async {
    final name = await _promptText(context, 'Rename category', category.name, initial: category.name);
    if (name != null && name.trim().isNotEmpty) {
      await store.renameSpendCategory(category, name);
      setState(() {});
    }
  }

  Future<void> _addSub(SpendCategory category) async {
    final name = await _promptText(context, 'New sub-category', 'e.g. Streaming');
    if (name != null && name.trim().isNotEmpty) {
      await store.addSpendSubcategory(category, name);
      setState(() {});
    }
  }

  Future<String?> _promptText(BuildContext context, String title, String hint,
      {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? Brand.deep : Brand.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Surfaces.heading(dark)),
        title: Text('Manage categories', style: display(17, Surfaces.heading(dark))),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: _addCategory,
            icon: Icon(Icons.add_circle_outline, color: Surfaces.accent(dark)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final categories = store.spendCategories;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ModuleCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(category.name,
                                      style: body(14.5, Surfaces.heading(dark),
                                          weight: FontWeight.w700)),
                                ),
                                IconButton(
                                  onPressed: () => _renameCategory(category),
                                  icon: Icon(Icons.edit_outlined,
                                      size: 16, color: Surfaces.muted(dark)),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await store.removeSpendCategory(category);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.delete_outline,
                                      size: 16, color: Colors.redAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final sub in category.subcategories)
                                  Chip(
                                    label: Text(sub, style: body(11.5, Surfaces.bodyText(dark))),
                                    backgroundColor: Surfaces.card(dark),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () async {
                                      await store.removeSpendSubcategory(category, sub);
                                      setState(() {});
                                    },
                                  ),
                                ActionChip(
                                  label: const Text('+ Add'),
                                  onPressed: () => _addSub(category),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

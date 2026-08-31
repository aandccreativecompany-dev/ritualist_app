import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

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
                          _BudgetCard(dark: dark),
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 22),
                          _SavingsSection(dark: dark),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _AddSpendScreen(existing: entry))),
      child: ModuleCard(
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
              tooltip: 'Delete',
              onPressed: () => store.removeSpendEntry(entry),
              icon: Icon(Icons.close, size: 16, color: Surfaces.muted(dark)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen add/edit-expense form — Save is pinned in the AppBar, same
/// keyboard-safe pattern established for the journaling entry screen. Pass
/// `existing` to edit a previously logged entry in place instead of adding
/// a new one.
class _AddSpendScreen extends StatefulWidget {
  final SpendEntry? existing;
  const _AddSpendScreen({this.existing});
  @override
  State<_AddSpendScreen> createState() => _AddSpendScreenState();
}

class _AddSpendScreenState extends State<_AddSpendScreen> {
  late final _amountCtrl =
      TextEditingController(text: widget.existing?.amount.toStringAsFixed(0) ?? '');
  late final _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
  final _newSubCtrl = TextEditingController();
  String? _categoryId;
  String _subcategory = '';
  bool _isNeed = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _categoryId = existing.categoryId;
      _subcategory = existing.subcategory;
      _isNeed = existing.isNeed;
    } else if (store.spendCategories.isNotEmpty) {
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
    HapticFeedback.mediumImpact();
    final existing = widget.existing;
    if (existing != null) {
      await store.updateSpendEntry(
        existing,
        categoryId: categoryId,
        subcategory: _subcategory,
        amount: amount,
        isNeed: _isNeed,
        note: _noteCtrl.text,
      );
    } else {
      await store.addSpendEntry(
        categoryId: categoryId,
        subcategory: _subcategory,
        amount: amount,
        isNeed: _isNeed,
        note: _noteCtrl.text,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: _isEditing ? 'Updated' : 'Logged');
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
        title: Text(_isEditing ? 'Edit expense' : 'Log an expense',
            style: display(17, Surfaces.heading(dark))),
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
                GoldButton(
                    labelText: _isEditing ? 'Save changes' : 'Save expense', onPressed: _save),
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

/// Editable monthly/weekly wallet budget, with a live "spent so far vs
/// budget" progress bar. Uses a scroll-to-select wheel (see _BudgetSheet)
/// instead of a text field, per the explicit ask.
class _BudgetCard extends StatelessWidget {
  final bool dark;
  const _BudgetCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final budget = store.spendBudgetAmount;
    final period = store.spendBudgetPeriod;
    final spent = store.spentInCurrentBudgetPeriod;
    final pct = (budget == null || budget <= 0) ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = budget != null && spent > budget;

    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    budget == null ? 'SET A BUDGET' : '${period == 'weekly' ? 'WEEKLY' : 'MONTHLY'} BUDGET',
                    style: label(Surfaces.eyebrow(dark))),
              ),
              TextButton(
                onPressed: () => _openBudgetSheet(context),
                child: Text(budget == null ? 'Set budget' : 'Edit',
                    style: body(12, Surfaces.accent(dark), weight: FontWeight.w700)),
              ),
            ],
          ),
          if (budget == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'See how your spending stacks up against a monthly or weekly limit.',
                style: body(12.5, Surfaces.muted(dark)),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${spent.toStringAsFixed(0)}', style: display(22, Surfaces.heading(dark))),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('of ₹${budget.toStringAsFixed(0)}',
                      style: body(12.5, Surfaces.muted(dark))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Surfaces.accent(dark).withValues(alpha: 0.12),
                color: over ? Colors.redAccent : Surfaces.accent(dark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? 'Over budget by ₹${(spent - budget).toStringAsFixed(0)} this ${period == 'weekly' ? 'week' : 'month'}.'
                  : '₹${(budget - spent).toStringAsFixed(0)} left this ${period == 'weekly' ? 'week' : 'month'}.',
              style: body(11.5, over ? Colors.redAccent : Surfaces.muted(dark), weight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  void _openBudgetSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BudgetSheet(),
    );
  }
}

/// Scroll-to-select amount picker (two wheels — thousands and hundreds,
/// combining to the nearest ₹100) instead of typing, per the explicit ask
/// that a scroll picker be preferred where feasible.
class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet();
  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late String _period = store.spendBudgetPeriod;
  late int _thousands;
  late int _hundreds;

  @override
  void initState() {
    super.initState();
    final existing = (store.spendBudgetAmount ?? 10000).round();
    _thousands = (existing ~/ 1000).clamp(0, 200);
    _hundreds = ((existing % 1000) ~/ 100).clamp(0, 9);
  }

  double get _amount => (_thousands * 1000 + _hundreds * 100).toDouble();

  Future<void> _save() async {
    await store.setSpendBudget(_amount, _period);
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Budget saved');
    }
  }

  Future<void> _clear() async {
    await store.clearSpendBudget();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _enterManually() async {
    final ctrl = TextEditingController(text: _amount == 0 ? '' : _amount.toStringAsFixed(0));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Surfaces.sheet(dark),
        title: Text('Enter amount', style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: body(18, Surfaces.bodyText(dark), weight: FontWeight.w700),
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: body(13, Surfaces.muted(dark)))),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text.trim())),
            child: Text('Use amount',
                style: body(13, Surfaces.accent(dark), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result >= 0) {
      final rounded = result.round();
      setState(() {
        _thousands = (rounded ~/ 1000).clamp(0, 200);
        _hundreds = ((rounded % 1000) ~/ 100).clamp(0, 9);
      });
    }
  }

  Widget _wheel({
    required int itemCount,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      height: 150,
      width: 100,
      child: CupertinoPicker(
        itemExtent: 34,
        scrollController: FixedExtentScrollController(initialItem: selected),
        onSelectedItemChanged: onChanged,
        children: [for (var i = 0; i < itemCount; i++) Center(child: Text(label(i)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Surfaces.sheet(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set your budget', style: display(18, Surfaces.heading(dark))),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final p in const ['monthly', 'weekly'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: _period == p
                              ? Surfaces.accent(dark).withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _period == p ? Surfaces.accent(dark) : Surfaces.accentBorder(dark),
                          ),
                        ),
                        child: Text(p == 'monthly' ? 'Monthly' : 'Weekly',
                            style: body(13,
                                _period == p ? Surfaces.accent(dark) : Surfaces.bodyText(dark),
                                weight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('₹${_amount.toStringAsFixed(0)}',
                style: display(24, Surfaces.heading(dark)), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _wheel(
                  itemCount: 201,
                  selected: _thousands,
                  label: (i) => '$i,000',
                  onChanged: (i) => setState(() => _thousands = i),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('+', style: display(16, Surfaces.muted(dark))),
                ),
                _wheel(
                  itemCount: 10,
                  selected: _hundreds,
                  label: (i) => '${i}00',
                  onChanged: (i) => setState(() => _hundreds = i),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Scroll each wheel, or type the amount directly.',
                textAlign: TextAlign.center, style: body(11.5, Surfaces.muted(dark))),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _enterManually,
                icon: Icon(Icons.keyboard_alt_outlined, size: 16, color: Surfaces.accent(dark)),
                label: Text('Enter amount manually',
                    style: body(12.5, Surfaces.accent(dark), weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            GoldButton(labelText: 'Save budget', onPressed: _save),
            if (store.spendBudgetAmount != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clear,
                child: Text('Remove budget',
                    style: body(12.5, Colors.redAccent, weight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Savings & investments — a running total per real-world vehicle
/// (emergency fund, stocks, mutual funds, gold, and more), separate from
/// the Need/Want spend tracker above.
class _SavingsSection extends StatelessWidget {
  final bool dark;
  const _SavingsSection({required this.dark});

  IconData _iconFor(String type) {
    switch (kSavingsTypeIcons[type]) {
      case 'trending_up':
        return Icons.trending_up;
      case 'pie_chart_outline':
        return Icons.pie_chart_outline;
      case 'workspace_premium_outlined':
        return Icons.workspace_premium_outlined;
      case 'lock_clock_outlined':
        return Icons.lock_clock_outlined;
      case 'account_balance_outlined':
        return Icons.account_balance_outlined;
      case 'home_work_outlined':
        return Icons.home_work_outlined;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'savings_outlined':
        return Icons.savings_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final byType = store.savingsByType;
    final total = store.totalSavings;
    final recent = store.savingsEntries.take(6).toList();

    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('SAVINGS & INVESTMENTS', style: label(Surfaces.eyebrow(dark)))),
              IconButton(
                tooltip: 'Log a contribution',
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _AddSavingsScreen())),
                icon: Icon(Icons.add_circle_outline, size: 20, color: Surfaces.accent(dark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('₹${total.toStringAsFixed(0)}', style: display(22, Surfaces.heading(dark))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in kSavingsTypes)
                if (byType.containsKey(type))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Surfaces.accent(dark).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Surfaces.accent(dark).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconFor(type), size: 14, color: Surfaces.accent(dark)),
                        const SizedBox(width: 6),
                        Text('${kSavingsTypeLabels[type]}: ₹${byType[type]!.toStringAsFixed(0)}',
                            style: body(11.5, Surfaces.bodyText(dark), weight: FontWeight.w600)),
                      ],
                    ),
                  ),
            ],
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Track emergency fund, stocks, mutual funds, gold and more — tap + to log one.',
                style: body(12, Surfaces.muted(dark)),
              ),
            )
          else ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Surfaces.cardBorder(dark)),
            const SizedBox(height: 10),
            for (final entry in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(_iconFor(entry.type), size: 16, color: Surfaces.muted(dark)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [kSavingsTypeLabels[entry.type] ?? entry.type, entry.note]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: body(12.5, Surfaces.bodyText(dark)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('₹${entry.amount.toStringAsFixed(0)}',
                        style: body(12.5, Surfaces.heading(dark), weight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => store.removeSavingsEntry(entry),
                      icon: Icon(Icons.close, size: 14, color: Surfaces.muted(dark)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AddSavingsScreen extends StatefulWidget {
  const _AddSavingsScreen();
  @override
  State<_AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<_AddSavingsScreen> {
  String _type = kSavingsTypes.first;
  final _noteCtrl = TextEditingController();
  int _thousands = 1;
  int _hundreds = 0;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _amount => (_thousands * 1000 + _hundreds * 100).toDouble();

  Future<void> _save() async {
    if (_amount <= 0) return;
    HapticFeedback.mediumImpact();
    await store.addSavingsEntry(type: _type, amount: _amount, note: _noteCtrl.text);
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Logged');
    }
  }

  Future<void> _enterManually() async {
    final ctrl = TextEditingController(text: _amount == 0 ? '' : _amount.toStringAsFixed(0));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Surfaces.sheet(dark),
        title: Text('Enter amount', style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: body(18, Surfaces.bodyText(dark), weight: FontWeight.w700),
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: body(13, Surfaces.muted(dark)))),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text.trim())),
            child: Text('Use amount',
                style: body(13, Surfaces.accent(dark), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result >= 0) {
      final rounded = result.round();
      setState(() {
        _thousands = (rounded ~/ 1000).clamp(0, 200);
        _hundreds = ((rounded % 1000) ~/ 100).clamp(0, 9);
      });
    }
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
        title: Text('Log a contribution', style: display(17, Surfaces.heading(dark))),
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
                Text('TYPE', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in kSavingsTypes)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _type = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: _type == type
                                ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _type == type ? Surfaces.accent(dark) : Surfaces.accentBorder(dark),
                            ),
                          ),
                          child: Text(kSavingsTypeLabels[type] ?? type,
                              style: body(13,
                                  _type == type ? Surfaces.accent(dark) : Surfaces.bodyText(dark),
                                  weight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('AMOUNT', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                Text('₹${_amount.toStringAsFixed(0)}',
                    style: display(22, Surfaces.heading(dark))),
                Row(
                  children: [
                    SizedBox(
                      height: 140,
                      width: 100,
                      child: CupertinoPicker(
                        itemExtent: 34,
                        scrollController: FixedExtentScrollController(initialItem: _thousands),
                        onSelectedItemChanged: (i) => setState(() => _thousands = i),
                        children: [for (var i = 0; i < 201; i++) Center(child: Text('$i,000'))],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('+', style: display(16, Surfaces.muted(dark))),
                    ),
                    SizedBox(
                      height: 140,
                      width: 100,
                      child: CupertinoPicker(
                        itemExtent: 34,
                        scrollController: FixedExtentScrollController(initialItem: _hundreds),
                        onSelectedItemChanged: (i) => setState(() => _hundreds = i),
                        children: [for (var i = 0; i < 10; i++) Center(child: Text('${i}00'))],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: _enterManually,
                    icon: Icon(Icons.keyboard_alt_outlined, size: 16, color: Surfaces.accent(dark)),
                    label: Text('Enter amount manually',
                        style: body(12.5, Surfaces.accent(dark), weight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('NOTE (OPTIONAL)', style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, Surfaces.bodyText(dark)),
                  decoration: const InputDecoration(hintText: 'e.g. Monthly SIP'),
                ),
                const SizedBox(height: 26),
                GoldButton(labelText: 'Save contribution', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

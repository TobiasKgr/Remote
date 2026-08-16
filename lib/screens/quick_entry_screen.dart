import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/categorization_service.dart';
import '../services/quick_entry_parser.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import 'transaction_form_screen.dart';

/// Free-text quick entry: type something like "50€ Rewe gestern" and get a
/// parsed preview (amount/date/description/income-or-expense) before it's
/// handed off to the normal [TransactionFormScreen] to double-check and
/// save - keeps the fast path fast without skipping the review step.
class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({super.key});

  @override
  ConsumerState<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen> {
  final _controller = TextEditingController();
  QuickEntryDraft? _draft;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _draft = parseQuickEntry(_controller.text)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final draft = _draft;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Schnelleingabe'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Betrag, Beschreibung und optional ein Datum in einer Zeile eintippen, z. B. '
                '"50€ Rewe gestern" oder "12,99 Netflix". Ohne Datumsangabe wird heute angenommen.',
                style: TextStyle(color: colors.secondaryLabel, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppleCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'z. B. 50€ Rewe gestern',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => draft != null ? _continue(draft) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: draft == null
                    ? Text('Betrag nicht erkannt - bitte eine Zahl angeben.', style: TextStyle(color: colors.danger, fontSize: 13))
                    : _PreviewCard(draft: draft),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: draft == null ? null : () => _continue(draft),
                icon: const Icon(CupertinoIcons.chevron_right_circle_fill),
                label: const Text('Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue(QuickEntryDraft draft) {
    final categories = ref.read(categoryNotifierProvider);
    final history = ref.read(transactionNotifierProvider);
    final match = CategorizationService(categories, history: history).suggest(draft.description);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          initialDate: draft.date,
          initialDescription: draft.description,
          initialAmount: draft.amount,
          initialIsIncome: draft.isIncome,
          initialCategoryId: match?.categoryId,
          initialSubcategoryId: match?.subcategoryId,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.draft});

  final QuickEntryDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final color = draft.isIncome ? colors.success : colors.danger;

    return AppleCard(
      child: ListTile(
        leading: Icon(draft.isIncome ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_up_circle_fill, color: color),
        title: Text(draft.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateFormat.format(draft.date)),
        trailing: Text(
          currencyFormat.format(draft.isIncome ? draft.amount : -draft.amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

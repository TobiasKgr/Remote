import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/custom_import_profile.dart';
import '../providers/custom_import_profile_providers.dart';
import '../services/custom_format_parser.dart';
import '../services/pdf_import_service.dart' show ParsedTransaction;
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';

/// Guided wizard for teaching the app a new bank statement layout that
/// neither the generic nor a bank-specific parser recognizes. Rather than a
/// fully general rule engine (or requiring a new bespoke parser to be
/// written per bank, like [parseTargobankFinanzstatus]), this covers the
/// handful of variations that actually differ between German bank statement
/// layouts: date format, decimal separator, and whether the amount sits
/// right after the date or at the end of the booking line. The user pastes
/// a few example lines copied from their statement and sees a live preview
/// while adjusting these three settings.
class FormatAssistantScreen extends ConsumerStatefulWidget {
  const FormatAssistantScreen({super.key});

  @override
  ConsumerState<FormatAssistantScreen> createState() => _FormatAssistantScreenState();
}

class _FormatAssistantScreenState extends ConsumerState<FormatAssistantScreen> {
  final _sampleController = TextEditingController();
  final _nameController = TextEditingController();
  ImportDateFormat _dateFormat = ImportDateFormat.ddMMyyyy;
  ImportAmountPosition _amountPosition = ImportAmountPosition.endOfLine;
  ImportDecimalSeparator _decimalSeparator = ImportDecimalSeparator.comma;

  @override
  void initState() {
    super.initState();
    _sampleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sampleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  List<ParsedTransaction> get _preview {
    final sample = _sampleController.text;
    if (sample.trim().isEmpty) return const [];
    final profile = CustomImportProfile(
      id: 'preview',
      name: '',
      dateFormat: _dateFormat,
      amountPosition: _amountPosition,
      decimalSeparator: _decimalSeparator,
      createdAt: DateTime.now(),
    );
    return parseWithCustomProfile(sample, profile);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final preview = _preview;
    final canSave = preview.isNotEmpty && _nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Format anlernen'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Für Kontoauszüge, die die App noch nicht automatisch erkennt: ein paar Buchungszeilen aus dem '
                'PDF hier einfügen und Einstellungen anpassen, bis die Vorschau passt.',
                style: TextStyle(color: colors.secondaryLabel, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppleCard(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _sampleController,
                    maxLines: 6,
                    minLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'z. B.\n15.03.2026 REWE SAGT DANKE -45,67\n16.03.2026 GEHALT 3.000,00 H',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const AppleSectionHeader('Format-Einstellungen'),
            AppleGroupedSection(
              children: [
                _SettingsDropdown<ImportDateFormat>(
                  label: 'Datumsformat',
                  value: _dateFormat,
                  values: ImportDateFormat.values,
                  labelOf: (v) => v.label,
                  onChanged: (v) => setState(() => _dateFormat = v),
                ),
                _SettingsDropdown<ImportAmountPosition>(
                  label: 'Betrag steht',
                  value: _amountPosition,
                  values: ImportAmountPosition.values,
                  labelOf: (v) => v.label,
                  onChanged: (v) => setState(() => _amountPosition = v),
                ),
                _SettingsDropdown<ImportDecimalSeparator>(
                  label: 'Dezimaltrennzeichen',
                  value: _decimalSeparator,
                  values: ImportDecimalSeparator.values,
                  labelOf: (v) => v.label,
                  onChanged: (v) => setState(() => _decimalSeparator = v),
                ),
              ],
            ),
            const AppleSectionHeader('Vorschau'),
            if (_sampleController.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Noch keine Beispielzeilen eingefügt.', style: TextStyle(color: colors.secondaryLabel)),
              )
            else if (preview.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Keine Buchungen erkannt - Einstellungen oben anpassen.',
                  style: TextStyle(color: colors.danger),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${preview.length} Buchung(en) erkannt:',
                  style: TextStyle(color: colors.success, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              AppleGroupedSection(
                children: [
                  for (final t in preview)
                    ListTile(
                      title: Text(t.description.isEmpty ? '(keine Beschreibung)' : t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(dateFormat.format(t.date)),
                      trailing: Text(
                        currencyFormat.format(t.amount),
                        style: TextStyle(color: t.amount >= 0 ? colors.success : colors.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
            const AppleSectionHeader('Speichern'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppleCard(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Name (z. B. Bankname)', border: InputBorder.none),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: canSave ? _save : null,
                icon: const Icon(CupertinoIcons.checkmark_circle_fill),
                label: const Text('Format speichern'),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gespeicherte Formate werden bei künftigen PDF-Importen automatisch mitversucht, wenn die '
                'eingebaute Erkennung nichts findet.',
                style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final profile = CustomImportProfile(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      dateFormat: _dateFormat,
      amountPosition: _amountPosition,
      decimalSeparator: _decimalSeparator,
      createdAt: DateTime.now(),
    );
    await ref.read(customImportProfileNotifierProvider.notifier).add(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format "${profile.name}" gespeichert.')));
    Navigator.of(context).pop();
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({required this.label, required this.value, required this.values, required this.labelOf, required this.onChanged});

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [for (final v in values) DropdownMenuItem(value: v, child: Text(labelOf(v)))],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

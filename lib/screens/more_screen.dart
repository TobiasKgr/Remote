import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_tab.dart';
import '../providers/nav_settings_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';
import 'accounts_screen.dart';
import 'backup_screen.dart';
import 'import_history_screen.dart';
import 'format_assistant_screen.dart';
import 'net_worth_history_screen.dart';
import 'persons_screen.dart';
import 'quick_entry_screen.dart';
import 'recurring_payments_screen.dart';
import 'settings_screen.dart';

/// Central hub for everything that isn't one of the main tabs - styled like
/// the iOS Settings app (grouped sections, colored icon squares, chevrons)
/// so all of this stays one tap away instead of hidden behind a menu. Also
/// picks up any tab the user chose to hide from the main bar (see
/// [NavSettingsScreen]) in its own section, so nothing becomes unreachable.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenOrder = ref.watch(navOrderProvider);
    final hidden = ref.watch(navHiddenProvider);
    final hiddenTabs = [for (final key in hiddenOrder) if (hidden.contains(key)) kNavTabRegistry[key]!];

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Mehr'),
            if (hiddenTabs.isNotEmpty) ...[
              const AppleSectionHeader('Ausgeblendete Reiter'),
              AppleGroupedSection(
                children: [
                  for (final tab in hiddenTabs)
                    AppleSettingsRow(
                      icon: tab.icon,
                      iconColor: AppleColors.gray,
                      title: tab.label,
                      onTap: () => _push(context, tab.screenBuilder()),
                    ),
                ],
              ),
            ],
            const AppleSectionHeader('Konten & Personen'),
            AppleGroupedSection(
              children: [
                AppleSettingsRow(
                  icon: CupertinoIcons.person_2_fill,
                  iconColor: AppleColors.blue,
                  title: 'Personen verwalten',
                  onTap: () => _push(context, const PersonsScreen()),
                ),
                AppleSettingsRow(
                  icon: CupertinoIcons.building_2_fill,
                  iconColor: AppleColors.indigo,
                  title: 'Konten verwalten',
                  onTap: () => _push(context, const AccountsScreen()),
                ),
              ],
            ),
            const AppleSectionHeader('Finanzen'),
            AppleGroupedSection(
              children: [
                AppleSettingsRow(
                  icon: CupertinoIcons.bolt_fill,
                  iconColor: AppleColors.orange,
                  title: 'Schnelleingabe',
                  onTap: () => _push(context, const QuickEntryScreen()),
                ),
                AppleSettingsRow(
                  icon: CupertinoIcons.repeat,
                  iconColor: AppleColors.pink,
                  title: 'Abos & Verträge',
                  onTap: () => _push(context, const RecurringPaymentsScreen()),
                ),
                AppleSettingsRow(
                  icon: CupertinoIcons.chart_bar_alt_fill,
                  iconColor: AppleColors.green,
                  title: 'Vermögensentwicklung',
                  onTap: () => _push(context, const NetWorthHistoryScreen()),
                ),
              ],
            ),
            const AppleSectionHeader('Daten'),
            AppleGroupedSection(
              children: [
                AppleSettingsRow(
                  icon: CupertinoIcons.cloud_upload_fill,
                  iconColor: AppleColors.teal,
                  title: 'Backup exportieren/importieren',
                  onTap: () => _push(context, const BackupScreen()),
                ),
                AppleSettingsRow(
                  icon: CupertinoIcons.clock_fill,
                  iconColor: AppleColors.brown,
                  title: 'Import-Verlauf',
                  onTap: () => _push(context, const ImportHistoryScreen()),
                ),
                AppleSettingsRow(
                  icon: CupertinoIcons.wand_stars,
                  iconColor: AppleColors.purple,
                  title: 'Format anlernen',
                  subtitle: 'Für PDFs, die die App noch nicht erkennt',
                  onTap: () => _push(context, const FormatAssistantScreen()),
                ),
              ],
            ),
            const AppleSectionHeader('App'),
            AppleGroupedSection(
              children: [
                AppleSettingsRow(
                  icon: CupertinoIcons.gear_solid,
                  iconColor: AppleColors.gray,
                  title: 'Einstellungen',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_tab.dart';
import '../providers/nav_settings_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_widgets.dart';

/// Lets the user reorder the tabs in the main navigation bar/rail (up/down)
/// and choose, per tab, whether it shows directly in the bar or is tucked
/// under "Mehr" instead - see [NavOrderNotifier]/[NavHiddenNotifier].
/// "Übersicht" can be moved but not hidden, so there's always a working
/// home tab; "Mehr" itself isn't listed here - it's always the last, fixed
/// overflow entry.
class NavSettingsScreen extends ConsumerWidget {
  const NavSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(navOrderProvider);
    final hidden = ref.watch(navHiddenProvider);
    final colors = context.appleColors;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Navigation anpassen'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Reihenfolge der Reiter mit den Pfeilen ändern und pro Reiter festlegen, ob er direkt in der '
                'Leiste erscheint oder unter "Mehr" versteckt wird. "Übersicht" bleibt immer direkt erreichbar, '
                '"Mehr" steht immer als letzter Reiter fest.',
                style: TextStyle(color: colors.secondaryLabel, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            AppleGroupedSection(
              children: [
                for (var i = 0; i < order.length; i++)
                  _TabRow(
                    tab: kNavTabRegistry[order[i]]!,
                    isHidden: hidden.contains(order[i]),
                    isFirst: i == 0,
                    isLast: i == order.length - 1,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabRow extends ConsumerWidget {
  const _TabRow({required this.tab, required this.isHidden, required this.isFirst, required this.isLast});

  final NavTabDefinition tab;
  final bool isHidden;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appleColors;

    return ListTile(
      leading: Icon(tab.icon, color: colors.label),
      title: Text(tab.label),
      subtitle: tab.canHide
          ? Text(isHidden ? 'Unter "Mehr" versteckt' : 'Direkt in der Leiste')
          : const Text('Immer direkt erreichbar'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.canHide)
            Switch(
              value: !isHidden,
              onChanged: (visible) => ref.read(navHiddenProvider.notifier).setHidden(tab.key, !visible),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_up),
            onPressed: isFirst ? null : () => ref.read(navOrderProvider.notifier).moveUp(tab.key),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_down),
            onPressed: isLast ? null : () => ref.read(navOrderProvider.notifier).moveDown(tab.key),
          ),
        ],
      ),
    );
  }
}

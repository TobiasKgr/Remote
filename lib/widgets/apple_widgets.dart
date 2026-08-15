import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Big, bold, left-aligned page heading shown at the top of a screen's
/// scrollable body - the iOS "Large Title" navigation-bar pattern, without
/// the complexity of an actual collapsing [SliverAppBar]. Pair with an
/// [AppBar] that has no title (see screens) so the compact bar above stays
/// unobtrusive, matching how Settings/Mail/Wallet etc. do it on iOS.
class AppleLargeTitle extends StatelessWidget {
  const AppleLargeTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.displayMedium)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small, gray, all-caps section header used above a [AppleGroupedSection] -
/// mirrors iOS grouped-table-view section titles (e.g. "ALLGEMEIN").
class AppleSectionHeader extends StatelessWidget {
  const AppleSectionHeader(this.title, {super.key, this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 6)});

  final String title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

/// A rounded, inset card grouping a set of rows with hairline dividers
/// between them - the iOS "grouped table view" section look, used for
/// settings-style lists, forms and any set of related items.
class AppleGroupedSection extends StatelessWidget {
  const AppleGroupedSection({super.key, required this.children, this.margin = const EdgeInsets.symmetric(horizontal: 16)});

  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final separator = context.appleColors.separator;
    return Padding(
      padding: margin,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 0.5, thickness: 0.5, color: separator, indent: 16),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded card used for a single freestanding item (e.g. a transaction, an
/// account, an asset) that isn't part of a grouped section - just a
/// convenience wrapper around the themed [Card] with consistent margin.
class AppleCard extends StatelessWidget {
  const AppleCard({super.key, required this.child, this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 10)});

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: margin, child: Card(clipBehavior: Clip.antiAlias, child: child));
  }
}

/// A single row in an iOS "Settings.app" style list: a colored, rounded-
/// square icon on the left (as seen in Einstellungen/Settings), a title,
/// an optional subtitle, and a trailing chevron when [onTap] is set - use
/// inside an [AppleGroupedSection] to build a settings-style hub screen.
class AppleSettingsRow extends StatelessWidget {
  const AppleSettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? (onTap == null ? null : Icon(CupertinoIcons.chevron_right, size: 15, color: context.appleColors.secondaryLabel)),
      onTap: onTap,
    );
  }
}

/// Prominent "hero" stat card (e.g. current balance, net worth) - larger
/// padding, bigger number, optional accent-tinted background.
class AppleHeroCard extends StatelessWidget {
  const AppleHeroCard({super.key, required this.label, required this.value, this.subtitle, this.valueColor});

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.displayLarge?.copyWith(color: valueColor ?? theme.textTheme.displayLarge?.color)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

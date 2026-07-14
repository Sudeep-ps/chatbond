import 'package:flutter/material.dart';

import 'settings_tiles.dart';

class SettingsTileData {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTileData({
    required this.icon,
    required this.title,
    this.trailingText,
    this.trailing,
    this.onTap,
  });
}

class SettingsGroupCard extends StatelessWidget {
  final List<SettingsTileData> items;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;

  const SettingsGroupCard({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
    this.borderRadius = 24,
    this.backgroundColor = Colors.white,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Column(
            children: [
              SettingsTile(
                icon: item.icon,
                title: item.title,
                trailingText: item.trailingText,
                trailing: item.trailing,
                onTap: item.onTap,
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}

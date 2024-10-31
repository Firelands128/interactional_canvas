import 'package:flutter/material.dart';

class MenuEntry {
  const MenuEntry({
    required this.label,
    this.shortcut,
    this.isActivated,
    this.onPressed,
    this.menuChildren,
  }) : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');
  final String label;

  final MenuSerializableShortcut? shortcut;
  final bool Function()? isActivated;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  MenuEntry rename(String value) {
    return MenuEntry(
      label: value,
      shortcut: shortcut,
      menuChildren: menuChildren,
      onPressed: onPressed,
    );
  }

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      } else {
        return MenuItemButton(
          shortcut: selection.shortcut,
          trailingIcon: selection.isActivated != null && selection.isActivated!()
              ? const Icon(Icons.check)
              : SizedBox.fromSize(size: const Size(22, 0)),
          onPressed: selection.onPressed,
          child: Text(selection.label),
        );
      }
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(List<MenuEntry> menuEntries) {
    final result = <MenuSerializableShortcut, Intent>{};
    for (final menuEntry in menuEntries) {
      if (menuEntry.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(menuEntry.menuChildren!));
      } else {
        if (menuEntry.shortcut != null && menuEntry.onPressed != null) {
          result[menuEntry.shortcut!] = VoidCallbackIntent(
            menuEntry.onPressed!,
          );
        }
      }
    }
    return result;
  }
}

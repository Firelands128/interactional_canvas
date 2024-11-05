import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactional_canvas/interactional_canvas.dart';
import 'package:random_color/random_color.dart';

import 'actions.dart';
import 'circle.dart';
import 'menu_entry.dart';
import 'rectangle.dart';
import 'triangle.dart';

/// A widget that displays a menu for the [InteractionalCanvas].
class Menus extends StatefulWidget {
  const Menus({
    super.key,
    required this.controller,
  });

  final CanvasController controller;

  @override
  State<Menus> createState() => _MenusState();
}

class _MenusState extends State<Menus> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registerMenuShortcut();
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    widget.controller.removeListener(onUpdate);
    super.dispose();
  }

  List<MenuEntry> get menuEntries {
    return [
      createMenu,
      viewMenu,
      editMenu,
      settingsMenu,
    ];
  }

  MenuEntry get createMenu {
    return MenuEntry(
      label: 'Create',
      menuChildren: [
        MenuEntry(
          label: 'Circle',
          onPressed: () {
            final node = Node(
              key: UniqueKey(),
              label: 'Node ${widget.controller.nodes.length}',
              offset: widget.controller.mousePosition,
              size: Size.square(Random().nextDouble() * 200 + 100),
              child: Circle(color: RandomColor().randomColor()),
            );
            widget.controller.add(node);
          },
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyC,
          ),
        ),
        MenuEntry(
          label: 'Triangle',
          onPressed: () {
            final node = Node(
              key: UniqueKey(),
              label: 'Node ${widget.controller.nodes.length}',
              offset: widget.controller.mousePosition,
              size: Size(
                Random().nextDouble() * 200 + 100,
                Random().nextDouble() * 200 + 100,
              ),
              child: Triangle(color: RandomColor().randomColor()),
            );
            widget.controller.add(node);
          },
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyT,
          ),
        ),
        MenuEntry(
          label: 'Rectangle',
          onPressed: () {
            final node = Node(
              key: UniqueKey(),
              label: 'Node ${widget.controller.nodes.length}',
              offset: widget.controller.mousePosition,
              size: Size(
                Random().nextDouble() * 200 + 100,
                Random().nextDouble() * 200 + 100,
              ),
              child: Rectangle(color: RandomColor().randomColor()),
            );
            widget.controller.add(node);
          },
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyR,
          ),
        ),
      ],
    );
  }

  MenuEntry get viewMenu {
    return MenuEntry(
      label: 'View',
      menuChildren: [
        MenuEntry(
          label: 'Zoom In',
          onPressed: widget.controller.zoomIn,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.equal,
          ),
        ),
        MenuEntry(
          label: 'Zoom Out',
          onPressed: widget.controller.zoomOut,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.minus,
          ),
        ),
        MenuEntry(
          label: 'Move Up',
          onPressed: widget.controller.panUp,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.arrowUp,
          ),
        ),
        MenuEntry(
          label: 'Move Down',
          onPressed: widget.controller.panDown,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.arrowDown,
          ),
        ),
        MenuEntry(
          label: 'Move Left',
          onPressed: widget.controller.panLeft,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.arrowLeft,
          ),
        ),
        MenuEntry(
          label: 'Move Right',
          onPressed: widget.controller.panRight,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.arrowRight,
          ),
        ),
        MenuEntry(
          label: 'Reset',
          onPressed: widget.controller.zoomReset,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyR,
            meta: true,
            alt: true,
          ),
        ),
      ],
    );
  }

  MenuEntry get editMenu {
    return MenuEntry(
      label: 'Edit',
      menuChildren: [
        MenuEntry(
          label: 'Select All',
          onPressed: widget.controller.selectAll,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyA,
            meta: true,
          ),
        ),
        MenuEntry(
          label: 'Deselect All',
          onPressed: widget.controller.deselectAll,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyA,
            meta: true,
            shift: true,
          ),
        ),
        MenuEntry(
          label: 'Bring forward',
          onPressed: widget.controller.bringForward,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.bracketLeft,
            meta: true,
          ),
        ),
        MenuEntry(
          label: 'Bring to front',
          onPressed: widget.controller.bringToFront,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.bracketLeft,
          ),
        ),
        MenuEntry(
          label: 'Send backward',
          onPressed: widget.controller.sendBackward,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.bracketRight,
            meta: true,
          ),
        ),
        MenuEntry(
          label: 'Send to back',
          onPressed: widget.controller.sendToBack,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.bracketRight,
          ),
        ),
        MenuEntry(
          label: 'Rename',
          onPressed: () {
            if (widget.controller.selection.isNotEmpty) {
              widget.controller.focusNode.unfocus();
              final initialValue = widget.controller.selection.first.label;
              prompt(
                context,
                title: 'Rename child',
                value: initialValue,
              ).then((value) {
                widget.controller.focusNode.requestFocus();
                if (value == null) return;
                for (final selection in widget.controller.selection) {
                  selection.update(label: value);
                  widget.controller.update(selection);
                }
              });
            }
          },
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyR,
            meta: true,
          ),
        ),
        MenuEntry(
          label: 'Delete',
          onPressed: () {
            confirm(
              context,
              title: 'Delete Selection',
              content: 'Do you want to delete the current selection?',
            ).then(
              (value) {
                if (!value) return;
                widget.controller.deleteSelection();
              },
            );
          },
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyD,
            meta: true,
          ),
        ),
      ],
    );
  }

  MenuEntry get settingsMenu {
    return MenuEntry(
      label: 'Settings',
      menuChildren: [
        MenuEntry(
          label: 'Keep Ratio',
          isActivated: () => widget.controller.keepRatio,
          onPressed: widget.controller.toggleKeepRatio,
        ),
        MenuEntry(
          label: 'Show Grid',
          isActivated: () => widget.controller.showGrid,
          onPressed: widget.controller.toggleShowGrid,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyG,
            meta: true,
            alt: true,
          ),
        ),
        MenuEntry(
          label: 'Snap To Grid',
          isActivated: () => widget.controller.snapMovementToGrid,
          onPressed: widget.controller.toggleSnapToGrid,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyG,
            meta: true,
          ),
        ),
      ],
    );
  }

  void onUpdate() {
    if (mounted) setState(() {});
  }

  void registerMenuShortcut() {
    _shortcutsEntry?.dispose();
    final registry = ShortcutRegistry.of(context);
    final items = MenuEntry.shortcuts(menuEntries);
    if (items.isNotEmpty) {
      _shortcutsEntry = registry.addAll(items);
    } else {
      _shortcutsEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MenuBar(
            children: MenuEntry.build(menuEntries),
          ),
        ),
      ],
    );
  }
}

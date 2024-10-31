import 'package:flutter/material.dart';

import '../model/node.dart';

/// A [CustomMultiChildLayout] delegate that renders the nodes in the [InteractionalCanvas].
class NodesDelegate extends MultiChildLayoutDelegate {
  NodesDelegate(this.nodes);

  final List<Node> nodes;

  @override
  void performLayout(Size size) {
    for (final widget in nodes) {
      layoutChild(widget, BoxConstraints.tight(widget.size));
      positionChild(widget, widget.offset);
    }
  }

  @override
  bool shouldRelayout(NodesDelegate oldDelegate) => true;
}

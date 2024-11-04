enum ResizeMode {
  disabled,
  corners,
  edges,
  cornersAndEdges;

  bool get isEnabled => this != ResizeMode.disabled;

  bool get containsCornerHandles =>
      this == ResizeMode.corners || this == ResizeMode.cornersAndEdges;

  bool get containsEdgeHandles => this == ResizeMode.edges || this == ResizeMode.cornersAndEdges;
}

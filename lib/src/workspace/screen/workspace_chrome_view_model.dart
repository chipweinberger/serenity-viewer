import 'package:flutter/foundation.dart';

@immutable
class WorkspaceChromeViewModel {
  const WorkspaceChromeViewModel({
    required this.imageLabel,
    required this.videoLabel,
    required this.linkLabel,
    required this.isExposeMode,
    required this.showExposeSelectionHud,
    required this.selectedCount,
    required this.workspaceId,
    required this.workspaceZoom,
  });

  final String imageLabel;
  final String videoLabel;
  final String linkLabel;
  final bool isExposeMode;
  final bool showExposeSelectionHud;
  final int selectedCount;
  final String workspaceId;
  final double workspaceZoom;
}

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/window/workspace_window_model_helpers.dart';

class WorkspacePlaybackMutations {
  static const List<double> videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];

  static Workspace setVideoPosition(Workspace workspace, String windowId, int positionMs) {
    return WorkspaceWindowModelHelpers.updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(videoPositionMs: positionMs),
    );
  }

  static Workspace cycleVideoPlaybackSpeed(Workspace workspace, String windowId) {
    final currentWindow = WorkspaceWindowModelHelpers.videoWindowById(workspace, windowId);
    if (currentWindow == null) {
      return workspace;
    }

    final currentIndex = videoPlaybackSpeeds.indexWhere(
      (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
    );
    final nextSpeed = videoPlaybackSpeeds[(currentIndex + 1) % videoPlaybackSpeeds.length];

    return WorkspaceWindowModelHelpers.updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(videoPlaybackSpeed: nextSpeed),
    );
  }
}

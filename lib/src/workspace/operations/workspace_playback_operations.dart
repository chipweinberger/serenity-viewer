import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state_helpers.dart';

class WorkspacePlaybackOperations {
  static const List<double> videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];

  static WorkspaceState setVideoPosition(WorkspaceState workspace, String windowId, int positionMs) {
    return WorkspaceStateHelpers.updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(videoPositionMs: positionMs),
    );
  }

  static WorkspaceState cycleVideoPlaybackSpeed(WorkspaceState workspace, String windowId) {
    final currentWindow = WorkspaceStateHelpers.videoWindowById(workspace, windowId);
    if (currentWindow == null) {
      return workspace;
    }

    final currentIndex = videoPlaybackSpeeds.indexWhere(
      (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
    );
    final nextSpeed = videoPlaybackSpeeds[(currentIndex + 1) % videoPlaybackSpeeds.length];

    return WorkspaceStateHelpers.updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(videoPlaybackSpeed: nextSpeed),
    );
  }
}

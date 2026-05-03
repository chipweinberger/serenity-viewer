import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspacePlaybackApi {
  WorkspacePlaybackApi(this._controller);

  final WorkspaceController _controller;

  void setPosition(Workspace? workspace, String windowId, int positionMs) {
    _controller.playbackController.setVideoPosition(workspace, windowId, positionMs);
  }

  void cycleSpeed(Workspace? workspace, String windowId) {
    _controller.playbackController.cycleVideoPlaybackSpeed(workspace, windowId);
  }

  bool isPaused(String windowId) {
    return _controller.playbackController.isVideoWindowPaused(windowId);
  }

  void toggle(Workspace? workspace, String windowId) {
    _controller.playbackController.toggleVideoPlayback(workspace, windowId);
  }

  void pauseAll(Environment? environment) {
    _controller.playbackController.pauseAllVideos(environment);
  }

  void stopAll(Environment? environment) {
    pauseAll(environment);
  }

  void clearRuntimeState(String windowId) {
    _controller.playbackController.clearRuntimeState(windowId);
  }
}

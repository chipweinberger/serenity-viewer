part of 'workspace_controller.dart';

class WorkspacePlaybackApi {
  WorkspacePlaybackApi._(this._controller);

  final WorkspaceController _controller;

  void setPosition(Workspace? workspace, String windowId, int positionMs) {
    _controller._playbackController.setVideoPosition(workspace, windowId, positionMs);
  }

  void cycleSpeed(Workspace? workspace, String windowId) {
    _controller._playbackController.cycleVideoPlaybackSpeed(workspace, windowId);
  }

  bool isPaused(String windowId) {
    return _controller._playbackController.isVideoWindowPaused(windowId);
  }

  void toggle(Workspace? workspace, String windowId) {
    _controller._playbackController.toggleVideoPlayback(workspace, windowId);
  }

  void pauseAll(Environment? environment) {
    _controller._playbackController.pauseAllVideos(environment);
  }

  void stopAll(Environment? environment) {
    pauseAll(environment);
  }

  void clearRuntimeState(String windowId) {
    _controller._playbackController.clearRuntimeState(windowId);
  }
}

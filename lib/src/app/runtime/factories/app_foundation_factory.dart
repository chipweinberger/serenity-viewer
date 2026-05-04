import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

({
  AppUiController appUiController,
  MediaInspector mediaInspector,
  PlatformBridge platformBridge,
  SharedVideoControllerPool sharedVideoControllerPool,
  EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer,
  EnvironmentStore environmentStore,
}) createAppFoundation({
  required bool isRunningInWidgetTest,
  required EnvironmentStoreState environmentStoreState,
  required AppUiState appUiState,
  required WindowInteractionState windowInteractionState,
  required String Function() windowTitle,
  required ValueChanged<String> showMessage,
  required bool Function() mounted,
  required Future<void> Function() refreshWorkspaceTracking,
  required void Function(String workspaceId) markWorkspaceThumbnailDirty,
  required Future<void> Function() syncWindowTitle,
}) {
  final appUiController = AppUiController(
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    refreshWorkspaceTracking: refreshWorkspaceTracking,
  );
  final mediaInspector = MediaInspector(isRunningInWidgetTest: isRunningInWidgetTest);
  final platformBridge = PlatformBridge(
    environmentStoreState: environmentStoreState,
    isRunningInWidgetTest: isRunningInWidgetTest,
    windowTitle: windowTitle,
    showMessage: showMessage,
    isMounted: mounted,
  );
  final environmentStore = EnvironmentStore(
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    markWorkspaceThumbnailDirty: markWorkspaceThumbnailDirty,
    refreshWorkspaceTracking: refreshWorkspaceTracking,
    syncWindowTitle: syncWindowTitle,
  );
  final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
    createFileBookmark: platformBridge.createFileBookmark,
  );

  return (
    appUiController: appUiController,
    mediaInspector: mediaInspector,
    platformBridge: platformBridge,
    sharedVideoControllerPool: SharedVideoControllerPool(),
    environmentStore: environmentStore,
    environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
  );
}

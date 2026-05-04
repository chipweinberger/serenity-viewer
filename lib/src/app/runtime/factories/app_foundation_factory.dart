import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';

AppFoundation createAppFoundation({
  required AppRuntimeInputs inputs,
  required Future<void> Function() refreshWorkspaceTracking,
  required void Function(String workspaceId) markWorkspaceThumbnailDirty,
  required Future<void> Function() syncWindowTitle,
}) {
  final stateStore = inputs.stateStore;
  final environmentStoreState = stateStore.environmentStoreState;
  final appUiState = stateStore.appUiState;
  final windowInteractionState = stateStore.windowInteractionState;

  final appUiController = AppUiController(
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    commitStateChange: inputs.app.commitStateChange,
    refreshWorkspaceTracking: refreshWorkspaceTracking,
  );
  final mediaInspector = MediaInspector(isRunningInWidgetTest: inputs.isRunningInWidgetTest);
  final platformBridge = PlatformBridge(
    environmentStoreState: environmentStoreState,
    isRunningInWidgetTest: inputs.isRunningInWidgetTest,
    windowTitle: inputs.app.windowTitle,
    showMessage: inputs.app.showMessage,
    isMounted: inputs.app.mounted,
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

  return AppFoundation(
    appUiController: appUiController,
    mediaInspector: mediaInspector,
    platformBridge: platformBridge,
    sharedVideoControllerPool: SharedVideoControllerPool(),
    environmentStore: environmentStore,
    environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
  );
}

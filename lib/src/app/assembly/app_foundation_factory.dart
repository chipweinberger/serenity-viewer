import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';

class AppFoundationFactory {
  const AppFoundationFactory(this.config);

  final AppRuntimeConfig config;

  AppFoundation create({
    required Future<void> Function() refreshWorkspaceTracking,
    required void Function(String workspaceId) markWorkspaceThumbnailDirty,
    required Future<void> Function() syncWindowTitle,
  }) {
    final stateStore = config.stateStore;
    final environmentStoreState = stateStore.environmentStoreState;
    final appUiState = stateStore.appUiState;
    final windowInteractionState = stateStore.windowInteractionState;

    final appUiController = AppUiController(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      commitStateChange: config.shell.commitStateChange,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
    );
    final mediaInspector = MediaInspector(isRunningInWidgetTest: config.isRunningInWidgetTest);
    final platformBridge = PlatformBridge(
      environmentStoreState: environmentStoreState,
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      windowTitle: config.shell.windowTitle,
      showMessage: config.shell.showMessage,
      isMounted: config.shell.mounted,
    );
    final environmentStore = EnvironmentStore(
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
      markWorkspaceThumbnailDirty: markWorkspaceThumbnailDirty,
      commitStateChange: config.shell.commitStateChange,
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
}

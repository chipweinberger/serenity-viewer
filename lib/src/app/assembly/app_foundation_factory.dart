import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/media/video/media_bridge.dart';

class AppFoundationFactory {
  const AppFoundationFactory(this.config);

  final AppRuntimeConfig config;

  AppFoundation create({
    required Future<void> Function() refreshWorkspaceTracking,
    required void Function(String workspaceId) markWorkspaceThumbnailDirty,
    required Future<void> Function() syncWindowTitle,
  }) {
    final dependencies = config.dependencies;
    final environmentStoreState = dependencies.environmentStoreState;
    final appUiState = dependencies.appUiState;
    final windowInteractionState = dependencies.windowInteractionState;

    final appUiController = AppUiController(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      commitStateChange: config.shell.commitStateChange,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
    );
    final mediaBridge = MediaBridge(
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      showMessage: config.shell.showMessage,
      isMounted: config.shell.mounted,
    );
    final platformBridge = PlatformBridge(
      environmentStoreState: environmentStoreState,
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      windowTitle: config.shell.windowTitle,
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
      mediaBridge: mediaBridge,
      platformBridge: platformBridge,
      environmentStore: environmentStore,
      environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
    );
  }
}

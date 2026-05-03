import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';

class AppShellRuntimeFoundationFactory {
  const AppShellRuntimeFoundationFactory(this.config);

  final AppShellRuntimeConfig config;

  AppShellRuntimeFoundation create({
    required Future<void> Function() refreshWorkspaceTracking,
    required void Function(String workspaceId) markWorkspaceThumbnailDirty,
    required Future<void> Function() syncWindowTitle,
  }) {
    final dependencies = config.dependencies;
    final persistenceState = dependencies.persistenceState;
    final chromeState = dependencies.chromeState;
    final windowInteractionState = dependencies.windowInteractionState;

    final chromeController = ChromeController(
      chromeState: chromeState,
      windowInteractionState: windowInteractionState,
      commitStateChange: config.shell.commitStateChange,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
    );
    final mediaBridge = MediaBridge(
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      showMessage: config.shell.showMessage,
      isMounted: config.shell.mounted,
    );
    final appShellPlatformBridge = AppShellPlatformBridge(
      persistenceState: persistenceState,
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      windowTitle: config.shell.windowTitle,
    );
    final environmentController = EnvironmentController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      markWorkspaceThumbnailDirty: markWorkspaceThumbnailDirty,
      commitStateChange: config.shell.commitStateChange,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
      syncWindowTitle: syncWindowTitle,
    );
    final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
    );

    return AppShellRuntimeFoundation(
      chromeController: chromeController,
      mediaBridge: mediaBridge,
      appShellPlatformBridge: appShellPlatformBridge,
      environmentController: environmentController,
      environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
    );
  }
}

class AppShellRuntimeFoundation {
  const AppShellRuntimeFoundation({
    required this.chromeController,
    required this.mediaBridge,
    required this.appShellPlatformBridge,
    required this.environmentController,
    required this.environmentBookmarkSynchronizer,
  });

  final ChromeController chromeController;
  final MediaBridge mediaBridge;
  final AppShellPlatformBridge appShellPlatformBridge;
  final EnvironmentController environmentController;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
}

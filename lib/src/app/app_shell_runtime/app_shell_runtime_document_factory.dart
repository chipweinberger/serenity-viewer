import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime_foundation_factory.dart';
import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime_workspace_factory.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';

class AppShellRuntimeDocumentFactory {
  const AppShellRuntimeDocumentFactory(this.config);

  final AppShellRuntimeConfig config;

  SryDocumentCoordinator create({
    required AppShellRuntimeFoundation foundation,
    required AppShellRuntimeWorkspace workspace,
  }) {
    return SryDocumentCoordinator(
      persistenceState: config.dependencies.persistenceState,
      environmentController: foundation.environmentController,
      context: config.shell.context,
      mounted: config.shell.mounted,
      seedEnvironment: config.environment.seedEnvironment,
      showMessage: config.shell.showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: workspace.thumbnailController.refreshActiveWorkspaceIfNeeded,
      storeLastEnvironmentPath: foundation.appShellPlatformBridge.storeLastEnvironmentPath,
      syncWindowTitle: foundation.appShellPlatformBridge.syncWindowTitle,
      resolveFileBookmark: foundation.appShellPlatformBridge.resolveFileBookmark,
      createFileBookmark: foundation.appShellPlatformBridge.createFileBookmark,
      thumbnailDirectory: foundation.appShellPlatformBridge.thumbnailDirectory,
      updateEnvironment: config.environment.updateEnvironment,
      saveEnvironment: config.environment.saveEnvironment,
    );
  }
}

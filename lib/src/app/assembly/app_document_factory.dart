import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

class AppDocumentFactory {
  const AppDocumentFactory(this.config);

  final AppRuntimeConfig config;

  DocumentCoordinator create({required AppFoundation foundation, required AppWorkspaceServices workspace}) {
    return DocumentCoordinator(
      environmentStoreState: config.ownedState.environmentStoreState,
      environmentStore: foundation.environmentStore,
      context: config.shell.context,
      mounted: config.shell.mounted,
      seedEnvironment: config.environment.seedEnvironment,
      showMessage: config.shell.showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: workspace.thumbnailController.refreshActiveWorkspaceIfNeeded,
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      syncWindowTitle: foundation.platformBridge.syncWindowTitle,
      resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
      updateEnvironment: config.environment.updateEnvironment,
      saveEnvironment: config.environment.saveEnvironment,
    );
  }
}

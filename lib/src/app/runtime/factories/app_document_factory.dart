import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

AppDocument createAppDocument({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
}) {
  final documentCoordinator = DocumentCoordinator(
    environmentStoreState: inputs.stateStore.environmentStoreState,
    environmentStore: foundation.environmentStore,
    context: inputs.app.context,
    mounted: inputs.app.mounted,
    seedEnvironment: inputs.environment.seedEnvironment,
    showMessage: inputs.app.showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: workspace.thumbnailController.refreshActiveWorkspaceIfNeeded,
    storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
    syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
    updateEnvironment: inputs.environment.updateEnvironment,
    saveEnvironment: inputs.environment.saveEnvironment,
  );

  return AppDocument(documentCoordinator: documentCoordinator);
}

import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';

DocumentCoordinator createAppDocumentCoordinator({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
}) {
  return DocumentCoordinator(
    environmentStoreState: inputs.stateStore.environmentStoreState,
    environmentStore: foundation.environmentStore,
    context: inputs.context,
    mounted: inputs.mounted,
    seedEnvironment: inputs.seedEnvironment,
    showMessage: inputs.showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: workspace.thumbnailController.refreshActiveWorkspaceIfNeeded,
    storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
    syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
    updateEnvironment: inputs.updateEnvironment,
    saveEnvironment: inputs.saveEnvironment,
  );
}

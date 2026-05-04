import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';

class AppMenuState {
  const AppMenuState({
    required this.activeWorkspaceId,
    required this.focusedWindow,
    required this.focusedWindowIsSelected,
    required this.recentlyClosedWindows,
  });

  final String? activeWorkspaceId;
  final Window? focusedWindow;
  final bool focusedWindowIsSelected;
  final List<WorkspaceWindowHistoryEntry> recentlyClosedWindows;
}

class AppMenuAppActions {
  const AppMenuAppActions({required this.showAboutSerenity, required this.openSettings});

  final VoidCallback showAboutSerenity;
  final Future<void> Function() openSettings;
}

class AppMenuFileActions {
  const AppMenuFileActions({
    required this.createEnvironment,
    required this.openEnvironment,
    required this.openAssets,
    required this.saveEnvironment,
    required this.saveEnvironmentAs,
  });

  final Future<void> Function() createEnvironment;
  final Future<void> Function() openEnvironment;
  final Future<void> Function() openAssets;
  final Future<void> Function() saveEnvironment;
  final Future<void> Function() saveEnvironmentAs;
}

class AppMenuAssetActions {
  const AppMenuAssetActions({
    required this.revealAssetInFinder,
    required this.toggleWindowSelected,
    required this.fitWindowToContent,
    required this.restorePreviousWindowZOrder,
    required this.convertVideoWindowToJpeg,
    required this.closeWindow,
  });

  final Future<void> Function(Asset asset) revealAssetInFinder;
  final ValueChanged<String> toggleWindowSelected;
  final ValueChanged<String> fitWindowToContent;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final Future<void> Function(String windowId) convertVideoWindowToJpeg;
  final void Function(String workspaceId, String windowId) closeWindow;
}

class AppMenuWorkspaceActions {
  const AppMenuWorkspaceActions({
    required this.toggleExpose,
    required this.toggleWorkspaceOverview,
    required this.createWorkspace,
    required this.switchToPreviousWorkspace,
    required this.switchToNextWorkspace,
    required this.fitWorkspaceViewportToContent,
    required this.confirmCollateWorkspaceWindows,
    required this.pauseAllVideos,
    required this.showNoWorkspaceToRenameMessage,
    required this.renameWorkspace,
    required this.showNoWorkspaceToDeleteMessage,
    required this.confirmDeleteWorkspace,
  });

  final VoidCallback toggleExpose;
  final VoidCallback toggleWorkspaceOverview;
  final VoidCallback createWorkspace;
  final VoidCallback switchToPreviousWorkspace;
  final VoidCallback switchToNextWorkspace;
  final VoidCallback fitWorkspaceViewportToContent;
  final Future<void> Function() confirmCollateWorkspaceWindows;
  final VoidCallback pauseAllVideos;
  final VoidCallback showNoWorkspaceToRenameMessage;
  final Future<void> Function(String workspaceId) renameWorkspace;
  final VoidCallback showNoWorkspaceToDeleteMessage;
  final Future<void> Function(String workspaceId) confirmDeleteWorkspace;
}

class AppMenuWindowActions {
  const AppMenuWindowActions({required this.restoreRecentlyClosedWindow});

  final void Function([WorkspaceWindowHistoryEntry? entry]) restoreRecentlyClosedWindow;
}

AppMenuState _buildAppMenuState({
  required AppStateStore state,
  required WorkspaceWindowController workspaceWindowController,
  required WorkspaceController workspaceController,
}) {
  final focusedWindow = workspaceWindowController.focusedWindowOrNull();
  final focusedWindowIsSelected = focusedWindow != null && workspaceController.expose.contains(focusedWindow.asset.id);

  return AppMenuState(
    activeWorkspaceId: state.environmentStoreState.environment?.activeWorkspaceId,
    focusedWindow: focusedWindow,
    focusedWindowIsSelected: focusedWindowIsSelected,
    recentlyClosedWindows: state.workspaceWindowHistoryState.entries,
  );
}

AppMenuAppActions _buildAppMenuAppActions({
  required AppFeedbackController feedback,
  required AppSettingsController settings,
}) {
  return AppMenuAppActions(showAboutSerenity: feedback.showAboutSerenity, openSettings: settings.openSettings);
}

AppMenuFileActions _buildAppMenuFileActions({
  required DocumentCoordinator documentCoordinator,
  required Future<void> Function() openAssets,
}) {
  return AppMenuFileActions(
    createEnvironment: documentCoordinator.createDocument,
    openEnvironment: documentCoordinator.openDocument,
    openAssets: openAssets,
    saveEnvironment: documentCoordinator.saveDocument,
    saveEnvironmentAs: documentCoordinator.saveDocumentAs,
  );
}

AppMenuAssetActions _buildAppMenuAssetActions({
  required Future<void> Function(Asset asset) revealAssetInFinder,
  required EnvironmentController environmentController,
  required WorkspaceWindowController workspaceWindowController,
  required WorkspaceVideoConversionController workspaceVideoConversionController,
  required WorkspaceWindowHistoryController workspaceWindowHistoryController,
}) {
  return AppMenuAssetActions(
    revealAssetInFinder: revealAssetInFinder,
    toggleWindowSelected: environmentController.navigation.toggleSelectedWindow,
    fitWindowToContent: workspaceWindowController.fitWindowToContent,
    restorePreviousWindowZOrder: workspaceWindowController.restorePreviousWindowZOrder,
    convertVideoWindowToJpeg: workspaceVideoConversionController.convertVideoWindowToJpeg,
    closeWindow: workspaceWindowHistoryController.removeWindow,
  );
}

AppMenuWorkspaceActions _buildAppMenuWorkspaceActions({
  required AppUiController appUiController,
  required EnvironmentController environmentController,
  required WorkspaceWindowController workspaceWindowController,
  required WorkspaceCollateController workspaceCollateController,
  required AppFeedbackController feedback,
}) {
  return AppMenuWorkspaceActions(
    toggleExpose: appUiController.toggleExpose,
    toggleWorkspaceOverview: environmentController.navigation.toggleOverview,
    createWorkspace: environmentController.management.create,
    switchToPreviousWorkspace: () => environmentController.navigation.switchWorkspace(-1),
    switchToNextWorkspace: () => environmentController.navigation.switchWorkspace(1),
    fitWorkspaceViewportToContent: workspaceWindowController.fitWorkspaceViewportToContent,
    confirmCollateWorkspaceWindows: workspaceCollateController.confirmCollateWorkspaceWindows,
    pauseAllVideos: workspaceWindowController.pauseAllVideos,
    showNoWorkspaceToRenameMessage: () => feedback.showMessage('There is no workspace to rename.'),
    renameWorkspace: environmentController.management.renameWorkspace,
    showNoWorkspaceToDeleteMessage: () => feedback.showMessage('There is no workspace to delete.'),
    confirmDeleteWorkspace: environmentController.management.confirmDeleteWorkspace,
  );
}

AppMenuWindowActions _buildAppMenuWindowActions({
  required WorkspaceWindowHistoryController workspaceWindowHistoryController,
}) {
  return AppMenuWindowActions(
    restoreRecentlyClosedWindow: workspaceWindowHistoryController.restoreRecentlyClosedWindow,
  );
}

({
  AppMenuState state,
  AppMenuAppActions app,
  AppMenuFileActions file,
  AppMenuAssetActions asset,
  AppMenuWorkspaceActions workspace,
  AppMenuWindowActions window,
}) buildAppMenuBindings(BuildContext context) {
  final state = context.read<AppStateStore>();
  final runtime = context.read<AppRuntime>();
  final appUiController = context.read<AppUiController>();
  final documentCoordinator = context.read<DocumentCoordinator>();
  final workspaceWindowController = context.read<WorkspaceWindowController>();
  final workspaceController = context.read<WorkspaceController>();
  final environmentController = context.read<EnvironmentController>();
  final workspaceVideoConversionController = context.read<WorkspaceVideoConversionController>();
  final workspaceWindowHistoryController = context.read<WorkspaceWindowHistoryController>();
  final workspaceCollateController = context.read<WorkspaceCollateController>();
  final feedback = context.read<AppFeedbackController>();
  final settings = context.read<AppSettingsController>();

  return (
    state: _buildAppMenuState(
      state: state,
      workspaceWindowController: workspaceWindowController,
      workspaceController: workspaceController,
    ),
    app: _buildAppMenuAppActions(feedback: feedback, settings: settings),
    file: _buildAppMenuFileActions(
      documentCoordinator: documentCoordinator,
      openAssets: runtime.workspaceAssetPickerController.pickAndImportAssets,
    ),
    asset: _buildAppMenuAssetActions(
      revealAssetInFinder: runtime.platformBridge.revealAssetInFinder,
      environmentController: environmentController,
      workspaceWindowController: workspaceWindowController,
      workspaceVideoConversionController: workspaceVideoConversionController,
      workspaceWindowHistoryController: workspaceWindowHistoryController,
    ),
    workspace: _buildAppMenuWorkspaceActions(
      appUiController: appUiController,
      environmentController: environmentController,
      workspaceWindowController: workspaceWindowController,
      workspaceCollateController: workspaceCollateController,
      feedback: feedback,
    ),
    window: _buildAppMenuWindowActions(workspaceWindowHistoryController: workspaceWindowHistoryController),
  );
}

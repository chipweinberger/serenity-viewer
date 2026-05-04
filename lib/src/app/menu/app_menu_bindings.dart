import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';

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

class AppMenuBindings {
  const AppMenuBindings({
    required this.state,
    required this.app,
    required this.file,
    required this.asset,
    required this.workspace,
    required this.window,
  });

  final AppMenuState state;
  final AppMenuAppActions app;
  final AppMenuFileActions file;
  final AppMenuAssetActions asset;
  final AppMenuWorkspaceActions workspace;
  final AppMenuWindowActions window;
}

class AppMenuBindingBuilder {
  const AppMenuBindingBuilder({
    required this.state,
    required this.foundation,
    required this.documents,
    required this.workspace,
    required this.feedback,
    required this.settings,
    required this.openAssets,
    required this.confirmCollateWorkspaceWindows,
  });

  final AppRuntimeState state;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  final AppFeedbackController feedback;
  final AppSettingsController settings;
  final Future<void> Function() openAssets;
  final Future<void> Function() confirmCollateWorkspaceWindows;

  AppMenuState _buildState() {
    final focusedWindow = workspace.workspaceWindowController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && workspace.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppMenuState(
      activeWorkspaceId: state.environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: state.workspaceWindowHistoryState.entries,
    );
  }

  AppMenuAppActions _buildAppActions() {
    return AppMenuAppActions(showAboutSerenity: feedback.showAboutSerenity, openSettings: settings.openSettings);
  }

  AppMenuFileActions _buildFileActions() {
    return AppMenuFileActions(
      createEnvironment: documents.documentCoordinator.createDocument,
      openEnvironment: documents.documentCoordinator.openDocument,
      openAssets: openAssets,
      saveEnvironment: documents.documentCoordinator.saveDocument,
      saveEnvironmentAs: documents.documentCoordinator.saveDocumentAs,
    );
  }

  AppMenuAssetActions _buildAssetActions() {
    return AppMenuAssetActions(
      revealAssetInFinder: foundation.platformBridge.revealAssetInFinder,
      toggleWindowSelected: workspace.environmentController.navigation.toggleSelectedWindow,
      fitWindowToContent: workspace.workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: workspace.workspaceWindowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: workspace.workspaceVideoConversionController.convertVideoWindowToJpeg,
      closeWindow: workspace.workspaceWindowHistoryController.removeWindow,
    );
  }

  AppMenuWorkspaceActions _buildWorkspaceActions() {
    return AppMenuWorkspaceActions(
      toggleExpose: foundation.appUiController.toggleExpose,
      toggleWorkspaceOverview: workspace.environmentController.navigation.toggleOverview,
      createWorkspace: workspace.environmentController.management.create,
      switchToPreviousWorkspace: () => workspace.environmentController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => workspace.environmentController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: workspace.workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: confirmCollateWorkspaceWindows,
      pauseAllVideos: workspace.workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: workspace.environmentController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: workspace.environmentController.management.confirmDeleteWorkspace,
    );
  }

  AppMenuWindowActions _buildWindowActions() {
    return AppMenuWindowActions(
      restoreRecentlyClosedWindow: workspace.workspaceWindowHistoryController.restoreRecentlyClosedWindow,
    );
  }

  AppMenuBindings build() {
    return AppMenuBindings(
      state: _buildState(),
      app: _buildAppActions(),
      file: _buildFileActions(),
      asset: _buildAssetActions(),
      workspace: _buildWorkspaceActions(),
      window: _buildWindowActions(),
    );
  }
}

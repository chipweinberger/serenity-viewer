import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_environment_mutations.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';

typedef SerenityEnvironmentCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceThumbnailMarker = void Function(String workspaceId);

class EnvironmentStore {
  EnvironmentStore({
    required this.environmentStoreState,
    required this.appUiState,
    required this.markWorkspaceThumbnailDirty,
    required this.commitStateChange,
    required this.refreshWorkspaceTracking,
    required this.syncWindowTitle,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final SerenityWorkspaceThumbnailMarker markWorkspaceThumbnailDirty;
  final SerenityEnvironmentCommit commitStateChange;
  final VoidCallback refreshWorkspaceTracking;
  final Future<void> Function() syncWindowTitle;

  void updateEnvironment(Environment nextEnvironment) {
    commitStateChange(() {
      environmentStoreState.environment = nextEnvironment;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
    markDirty();
  }

  void replaceWorkspace(Workspace nextWorkspace, {bool queueThumbnail = true}) {
    final environment = environmentStoreState.environment!;
    updateEnvironment(WorkspaceEnvironmentMutations.replaceWorkspace(environment, nextWorkspace));
    if (queueThumbnail) {
      markWorkspaceThumbnailDirty(nextWorkspace.id);
    }
  }

  void markDirty() {
    final shouldSyncTitle = !environmentStoreState.hasUnsavedChanges;
    environmentStoreState.hasUnsavedChanges = true;
    if (shouldSyncTitle) {
      unawaited(syncWindowTitle());
    }
  }

  void restoreWidgetTestEnvironment(Environment seedEnvironment) {
    commitStateChange(() {
      environmentStoreState.environment = seedEnvironment;
      environmentStoreState.isLoading = false;
    });
    refreshWorkspaceTracking();
  }

  void showMissingStartupState() {
    commitStateChange(() {
      environmentStoreState.environment = null;
      environmentStoreState.currentEnvironmentPath = null;
      environmentStoreState.isLoading = false;
      environmentStoreState.hasUnsavedChanges = false;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  bool shouldPromptForStartupEnvironment({required bool mounted}) {
    return mounted &&
        environmentStoreState.environment == null &&
        !environmentStoreState.isPromptingForStartupEnvironment;
  }

  void setStartupPromptInProgress(bool isPrompting) {
    environmentStoreState.isPromptingForStartupEnvironment = isPrompting;
  }

  void applyLoadedEnvironment({required Environment environment, required String path}) {
    commitStateChange(() {
      environmentStoreState.environment = environment;
      environmentStoreState.currentEnvironmentPath = path;
      environmentStoreState.hasUnsavedChanges = false;
      environmentStoreState.isLoading = false;
    });
    appUiState.showWorkspaceScreenDefaults();
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void applyCreatedEnvironment({required Environment environment, required String path}) {
    commitStateChange(() {
      environmentStoreState.environment = environment;
      environmentStoreState.currentEnvironmentPath = path;
      environmentStoreState.hasUnsavedChanges = false;
      environmentStoreState.isLoading = false;
    });
    appUiState.showWorkspaceScreenDefaults();
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void noteEnvironmentPathSaved(String path, {required bool mounted}) {
    if (mounted) {
      commitStateChange(() {
        environmentStoreState.currentEnvironmentPath = path;
        environmentStoreState.hasUnsavedChanges = false;
      });
      return;
    }

    environmentStoreState.currentEnvironmentPath = path;
    environmentStoreState.hasUnsavedChanges = false;
  }

  void applySavedEnvironment({
    required Environment originalEnvironment,
    required Environment savedEnvironment,
    required bool mounted,
  }) {
    if (mounted) {
      commitStateChange(() {
        if (!identical(savedEnvironment, originalEnvironment)) {
          environmentStoreState.environment = savedEnvironment;
        }
        environmentStoreState.hasUnsavedChanges = false;
      });
      return;
    }

    if (!identical(savedEnvironment, originalEnvironment)) {
      environmentStoreState.environment = savedEnvironment;
    }
    environmentStoreState.hasUnsavedChanges = false;
  }
}

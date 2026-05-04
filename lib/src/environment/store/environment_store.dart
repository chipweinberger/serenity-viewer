import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_environment_mutations.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';

typedef SerenityWorkspaceThumbnailMarker = void Function(String workspaceId);

class EnvironmentStore {
  EnvironmentStore({
    required this.environmentStoreState,
    required this.appUiState,
    required this.markWorkspaceThumbnailDirty,
    required this.refreshWorkspaceTracking,
    required this.syncWindowTitle,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final SerenityWorkspaceThumbnailMarker markWorkspaceThumbnailDirty;
  final VoidCallback refreshWorkspaceTracking;
  final Future<void> Function() syncWindowTitle;

  void updateEnvironment(Environment nextEnvironment) {
    environmentStoreState.update(environment: nextEnvironment);
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
    environmentStoreState.update(hasUnsavedChanges: true);
    if (shouldSyncTitle) {
      unawaited(syncWindowTitle());
    }
  }

  void restoreWidgetTestEnvironment(Environment seedEnvironment) {
    environmentStoreState.update(environment: seedEnvironment, isLoading: false);
    refreshWorkspaceTracking();
  }

  void showMissingStartupState() {
    environmentStoreState.update(
      environment: null,
      currentEnvironmentPath: null,
      isLoading: false,
      hasUnsavedChanges: false,
    );
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  bool shouldPromptForStartupEnvironment({required bool mounted}) {
    return mounted &&
        environmentStoreState.environment == null &&
        !environmentStoreState.isPromptingForStartupEnvironment;
  }

  void setStartupPromptInProgress(bool isPrompting) {
    environmentStoreState.update(isPromptingForStartupEnvironment: isPrompting);
  }

  void applyLoadedEnvironment({required Environment environment, required String path}) {
    environmentStoreState.update(
      environment: environment,
      currentEnvironmentPath: path,
      hasUnsavedChanges: false,
      isLoading: false,
    );
    appUiState.showWorkspaceScreenDefaults();
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void applyCreatedEnvironment({required Environment environment, required String path}) {
    environmentStoreState.update(
      environment: environment,
      currentEnvironmentPath: path,
      hasUnsavedChanges: false,
      isLoading: false,
    );
    appUiState.showWorkspaceScreenDefaults();
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void noteEnvironmentPathSaved(String path, {required bool mounted}) {
    environmentStoreState.update(currentEnvironmentPath: path, hasUnsavedChanges: false);
  }

  void applySavedEnvironment({
    required Environment originalEnvironment,
    required Environment savedEnvironment,
    required bool mounted,
  }) {
    if (identical(savedEnvironment, originalEnvironment)) {
      environmentStoreState.update(hasUnsavedChanges: false);
      return;
    }

    environmentStoreState.update(environment: savedEnvironment, hasUnsavedChanges: false);
  }
}

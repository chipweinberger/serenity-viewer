import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_environment_operations.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/app/app_environment_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresh_state.dart';

typedef SerenityEnvironmentCommit = void Function(VoidCallback update);

class EnvironmentController {
  EnvironmentController({
    required this.persistenceState,
    required this.chromeState,
    required this.thumbnailRefreshState,
    required this.commitStateChange,
    required this.refreshWorkspaceTracking,
    required this.syncWindowTitle,
  });

  final AppEnvironmentState persistenceState;
  final ChromeState chromeState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final SerenityEnvironmentCommit commitStateChange;
  final VoidCallback refreshWorkspaceTracking;
  final Future<void> Function() syncWindowTitle;

  void updateEnvironment(Environment nextEnvironment) {
    commitStateChange(() {
      persistenceState.environment = nextEnvironment;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
    markDirty();
  }

  void replaceWorkspace(Workspace nextWorkspace, {bool queueThumbnail = true}) {
    final environment = persistenceState.environment!;
    updateEnvironment(WorkspaceEnvironmentOperations.replaceWorkspace(environment, nextWorkspace));
    if (queueThumbnail) {
      thumbnailRefreshState.dirtyWorkspaces.add(nextWorkspace.id);
    }
  }

  void markDirty() {
    final shouldSyncTitle = !persistenceState.hasUnsavedChanges;
    persistenceState.hasUnsavedChanges = true;
    if (shouldSyncTitle) {
      unawaited(syncWindowTitle());
    }
  }

  void restoreWidgetTestEnvironment(Environment seedEnvironment) {
    commitStateChange(() {
      persistenceState.environment = seedEnvironment;
      persistenceState.isLoading = false;
    });
    refreshWorkspaceTracking();
  }

  void showMissingStartupState() {
    commitStateChange(() {
      persistenceState.environment = null;
      persistenceState.currentEnvironmentPath = null;
      persistenceState.isLoading = false;
      persistenceState.hasUnsavedChanges = false;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  bool shouldPromptForStartupEnvironment({required bool mounted}) {
    return mounted && persistenceState.environment == null && !persistenceState.isPromptingForStartupEnvironment;
  }

  void setStartupPromptInProgress(bool isPrompting) {
    persistenceState.isPromptingForStartupEnvironment = isPrompting;
  }

  void applyLoadedEnvironment({required Environment environment, required String path}) {
    commitStateChange(() {
      persistenceState.environment = environment;
      persistenceState.currentEnvironmentPath = path;
      persistenceState.hasUnsavedChanges = false;
      persistenceState.isLoading = false;
      chromeState.screen = SerenityScreen.workspace;
      chromeState.workspaceLayoutMode = WorkspaceLayoutMode.freeform;
      chromeState.editMode = false;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void applyCreatedEnvironment({required Environment environment, required String path}) {
    commitStateChange(() {
      persistenceState.environment = environment;
      persistenceState.currentEnvironmentPath = path;
      persistenceState.hasUnsavedChanges = false;
      persistenceState.isLoading = false;
      chromeState.screen = SerenityScreen.workspace;
      chromeState.workspaceLayoutMode = WorkspaceLayoutMode.freeform;
      chromeState.editMode = false;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  void noteEnvironmentPathSaved(String path, {required bool mounted}) {
    if (mounted) {
      commitStateChange(() {
        persistenceState.currentEnvironmentPath = path;
        persistenceState.hasUnsavedChanges = false;
      });
      return;
    }

    persistenceState.currentEnvironmentPath = path;
    persistenceState.hasUnsavedChanges = false;
  }

  void applySavedEnvironment({
    required Environment originalEnvironment,
    required Environment savedEnvironment,
    required bool mounted,
  }) {
    if (mounted) {
      commitStateChange(() {
        if (!identical(savedEnvironment, originalEnvironment)) {
          persistenceState.environment = savedEnvironment;
        }
        persistenceState.hasUnsavedChanges = false;
      });
      return;
    }

    if (!identical(savedEnvironment, originalEnvironment)) {
      persistenceState.environment = savedEnvironment;
    }
    persistenceState.hasUnsavedChanges = false;
  }
}

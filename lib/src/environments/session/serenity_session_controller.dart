import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/serenity_core.dart';
import 'package:serenity_viewer/src/workspace/serenity_workspace_mutations.dart';
import 'package:serenity_viewer/src/environments/session/serenity_session_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';
import 'package:serenity_viewer/src/settings/behavior/serenity_chrome_state.dart';
import 'package:serenity_viewer/src/environments/session/serenity_shell_persistence_state.dart';
import 'package:serenity_viewer/src/environments/persistence/serenity_thumbnail_refresh_state.dart';

typedef SerenitySessionStateCommit = void Function(VoidCallback update);

class SerenitySessionController {
  SerenitySessionController({
    required this.persistenceState,
    required this.chromeState,
    required this.thumbnailRefreshState,
    required this.commitStateChange,
    required this.refreshWorkspaceTracking,
    required this.syncWindowTitle,
  });

  final SerenityShellPersistenceState persistenceState;
  final SerenityChromeState chromeState;
  final SerenityThumbnailRefreshState thumbnailRefreshState;
  final SerenitySessionStateCommit commitStateChange;
  final VoidCallback refreshWorkspaceTracking;
  final Future<void> Function() syncWindowTitle;

  void updateSession(SerenitySessionState nextSession) {
    commitStateChange(() {
      persistenceState.session = nextSession;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
    markDirty();
  }

  void replaceWorkspace(WorkspaceState nextWorkspace, {bool queueThumbnail = true}) {
    final session = persistenceState.session!;
    updateSession(SerenityWorkspaceMutations.replaceWorkspace(session, nextWorkspace));
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

  void restoreWidgetTestSession(SerenitySessionState seedSession) {
    commitStateChange(() {
      persistenceState.session = seedSession;
      persistenceState.isLoading = false;
    });
    refreshWorkspaceTracking();
  }

  void showMissingStartupState() {
    commitStateChange(() {
      persistenceState.session = null;
      persistenceState.currentEnvironmentPath = null;
      persistenceState.isLoading = false;
      persistenceState.hasUnsavedChanges = false;
    });
    refreshWorkspaceTracking();
    unawaited(syncWindowTitle());
  }

  bool shouldPromptForStartupEnvironment({required bool mounted}) {
    return mounted && persistenceState.session == null && !persistenceState.isPromptingForStartupEnvironment;
  }

  void setStartupPromptInProgress(bool isPrompting) {
    persistenceState.isPromptingForStartupEnvironment = isPrompting;
  }

  void applyLoadedEnvironment({required SerenitySessionState session, required String path}) {
    commitStateChange(() {
      persistenceState.session = session;
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

  void applyCreatedEnvironment({required SerenitySessionState session, required String path}) {
    commitStateChange(() {
      persistenceState.session = session;
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

  void applySavedSessionState({
    required SerenitySessionState originalSession,
    required SerenitySessionState savedSession,
    required bool mounted,
  }) {
    if (mounted) {
      commitStateChange(() {
        if (!identical(savedSession, originalSession)) {
          persistenceState.session = savedSession;
        }
        persistenceState.hasUnsavedChanges = false;
      });
      return;
    }

    if (!identical(savedSession, originalSession)) {
      persistenceState.session = savedSession;
    }
    persistenceState.hasUnsavedChanges = false;
  }
}

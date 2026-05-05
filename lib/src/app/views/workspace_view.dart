import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceView extends StatelessWidget {
  const WorkspaceView({super.key});

  ({
    AppUiState appUiState,
    EnvironmentStoreState environmentStoreState,
    WindowInteractionState windowInteractionState,
    WorkspaceViewportState workspaceViewportState,
  })
  _watchState(BuildContext context) {
    return (
      appUiState: context.watch<AppUiState>(),
      environmentStoreState: context.watch<EnvironmentStoreState>(),
      windowInteractionState: context.watch<WindowInteractionState>(),
      workspaceViewportState: context.watch<WorkspaceViewportState>(),
    );
  }

  ({
    AppUiController appUiController,
    AppUiHandles appUiHandles,
    PlatformBridge platformBridge,
    EnvironmentController environmentController,
    WorkspaceController workspaceController,
    SharedVideoControllerPool sharedVideoControllerPool,
  })
  _readDependencies(BuildContext context) {
    return (
      appUiController: context.read<AppUiController>(),
      appUiHandles: context.read<AppUiHandles>(),
      platformBridge: context.read<PlatformBridge>(),
      environmentController: context.read<EnvironmentController>(),
      workspaceController: context.read<WorkspaceController>(),
      sharedVideoControllerPool: context.read<SharedVideoControllerPool>(),
    );
  }

  WorkspaceHudViewModel _buildWorkspaceHudViewModel({
    required Workspace activeWorkspace,
    required AppUiController appUiController,
    required int selectedExposeWindowCount,
  }) {
    final mediaCounts = workspaceMediaCounts(activeWorkspace);
    return WorkspaceHudViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: appUiController.isExposeMode,
      showExposeSelectionHud: appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: selectedExposeWindowCount,
      workspaceId: activeWorkspace.id,
      workspaceZoom: activeWorkspace.viewportZoom,
    );
  }

  String? _focusedWindowId(Workspace workspace, {required bool isExposeMode}) {
    if (isExposeMode || workspace.windows.isEmpty) {
      return null;
    }

    final windows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return windows.last.asset.id;
  }

  Set<String> _retainedSharedVideoWindowIds({
    required AppUiState appUiState,
    required EnvironmentStoreState environmentStoreState,
    required WindowInteractionState windowInteractionState,
    required MediaLoadPlan loadPlan,
  }) {
    final environment = environmentStoreState.environment;
    if (environment == null) {
      return const <String>{};
    }

    final pinnedWindowId = windowInteractionState.pinnedHoverWindowId;
    final isWorkspaceScreen = appUiState.screen == SerenityScreen.workspace;
    final retainedWindowIds = <String>{};

    for (final workspace in environment.workspaces) {
      final isActiveWorkspace = isWorkspaceScreen && workspace.id == environment.activeWorkspaceId;
      final isExposeMode = isActiveWorkspace && appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
      final focusedWindowId = _focusedWindowId(workspace, isExposeMode: isExposeMode);

      for (final window in workspace.windows) {
        if (window.asset.type != AssetType.video || !loadPlan.loadedAssetIds.contains(window.asset.id)) {
          continue;
        }

        final isPaused = !isActiveWorkspace || (windowInteractionState.pausedVideoWindows[window.asset.id] ?? true);
        final shouldRetainController =
            !isPaused || window.asset.id == focusedWindowId || window.asset.id == pinnedWindowId;
        if (shouldRetainController) {
          retainedWindowIds.add(window.asset.id);
        }
      }
    }

    return retainedWindowIds;
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);
    final environment = state.environmentStoreState.environment!;
    final activeWorkspace = deriveActiveWorkspace(state.environmentStoreState);
    final shouldLoadVideos = environment.autoLoadVideos || state.appUiState.shouldLoadVideos;
    final workspaceLoadPlan = buildWorkspaceLoadPlan(
      environment: environment,
      activeWorkspace: activeWorkspace,
      shouldLoadVideos: shouldLoadVideos,
    );
    final workspaceHudViewModel = _buildWorkspaceHudViewModel(
      activeWorkspace: activeWorkspace,
      appUiController: dependencies.appUiController,
      selectedExposeWindowCount: state.windowInteractionState.selectedExposeWindowIds.length,
    );
    final retainedSharedVideoWindowIds = _retainedSharedVideoWindowIds(
      appUiState: state.appUiState,
      environmentStoreState: state.environmentStoreState,
      windowInteractionState: state.windowInteractionState,
      loadPlan: workspaceLoadPlan,
    );

    dependencies.sharedVideoControllerPool.syncSharedVideoControllers(
      retainedVideoWindowIds: retainedSharedVideoWindowIds,
    );

    return WorkspaceScreen(
      environment: environment,
      appUiState: state.appUiState,
      windowInteractionState: state.windowInteractionState,
      workspaceViewportState: state.workspaceViewportState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: dependencies.sharedVideoControllerPool.sharedVideoForWindow,
      workspaceController: dependencies.workspaceController,
      environmentController: dependencies.environmentController,
      appUiController: dependencies.appUiController,
      appUiHandles: dependencies.appUiHandles,
      platformBridge: dependencies.platformBridge,
      mounted: () => context.mounted,
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        activeWorkspace: activeWorkspace,
        appUiController: dependencies.appUiController,
        environmentController: dependencies.environmentController,
        workspaceController: dependencies.workspaceController,
      ),
      shouldLoadVideos: shouldLoadVideos,
    );
  }
}

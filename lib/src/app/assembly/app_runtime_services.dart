import 'package:serenity_viewer/src/app/app_dependencies.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/session/environment_session.dart';
import 'package:serenity_viewer/src/environment/session/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/media/video/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/window/session/recently_closed_windows_state.dart';
import 'package:serenity_viewer/src/workspace/window/session/workspace_window_history_controller.dart';

class AppStateServices {
  const AppStateServices({
    required this.handles,
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.recentlyClosedWindowsState,
  });

  final AppHandles handles;
  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final RecentlyClosedWindowsState recentlyClosedWindowsState;
}

class AppFoundation {
  const AppFoundation({
    required this.appUiController,
    required this.mediaInspector,
    required this.platformBridge,
    required this.sharedVideoControllerPool,
    required this.environmentBookmarkSynchronizer,
    required this.environmentStore,
  });

  final AppUiController appUiController;
  final MediaInspector mediaInspector;
  final PlatformBridge platformBridge;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final EnvironmentStore environmentStore;
}

class AppDocument {
  const AppDocument({required this.documentCoordinator});

  final DocumentCoordinator documentCoordinator;
}

class AppWorkspaceServices {
  const AppWorkspaceServices({
    required this.thumbnailController,
    required this.videoConversionCoordinator,
    required this.workspaceMediaImportController,
    required this.workspaceLinksController,
    required this.workspaceController,
    required this.workspaceWindowController,
    required this.workspaceWindowHistoryController,
    required this.workspaceViewportSessionController,
    required this.environmentSession,
  });

  final ThumbnailController thumbnailController;
  final VideoConversionCoordinator videoConversionCoordinator;
  final WorkspaceMediaImportController workspaceMediaImportController;
  final WorkspaceLinksController workspaceLinksController;
  final WorkspaceController workspaceController;
  final WorkspaceWindowController workspaceWindowController;
  final WorkspaceWindowHistoryController workspaceWindowHistoryController;
  final WorkspaceViewportSessionController workspaceViewportSessionController;
  final EnvironmentSession environmentSession;
}

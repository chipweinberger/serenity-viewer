import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.appUiState,
    required this.environmentStoreState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.workspaceWindowHistoryState,
    required this.workspaceViewTrackingState,
    required this.uiHandles,
    required this.feedback,
    required this.settings,
    required this.runtime,
    required this.child,
  });

  final AppUiState appUiState;
  final EnvironmentStoreState environmentStoreState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final WorkspaceWindowHistoryState workspaceWindowHistoryState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final AppUiHandles uiHandles;
  final AppFeedbackController feedback;
  final AppSettingsController settings;
  final AppRuntime runtime;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppUiHandles>.value(value: uiHandles),
        Provider<AppFeedbackController>.value(value: feedback),
        Provider<AppSettingsController>.value(value: settings),
        ChangeNotifierProvider.value(value: appUiState),
        ChangeNotifierProvider.value(value: environmentStoreState),
        ChangeNotifierProvider.value(value: windowInteractionState),
        ChangeNotifierProvider.value(value: workspaceViewportState),
        ChangeNotifierProvider.value(value: thumbnailRefreshState),
        ChangeNotifierProvider.value(value: workspaceWindowHistoryState),
        ChangeNotifierProvider.value(value: workspaceViewTrackingState),
        Provider<AppUiController>.value(value: runtime.appUiController),
        Provider<SharedVideoControllerPool>.value(value: runtime.sharedVideoControllerPool),
        Provider<PlatformBridge>.value(value: runtime.platformBridge),
        Provider<EnvironmentStore>.value(value: runtime.environmentStore),
        Provider<DocumentCoordinator>.value(value: runtime.documentCoordinator),
        Provider<WorkspaceController>.value(value: runtime.workspaceController),
        Provider<EnvironmentController>.value(value: runtime.environmentController),
        Provider<WorkspaceExposeLayoutController>.value(value: runtime.workspaceExposeLayoutController),
        Provider<WorkspaceLinksController>.value(value: runtime.workspaceLinksController),
        Provider<WorkspaceLinksLauncher>.value(value: runtime.workspaceLinksLauncher),
        Provider<WorkspaceLinksPrompts>.value(value: runtime.workspaceLinksPrompts),
        Provider<ThumbnailController>.value(value: runtime.thumbnailController),
        Provider<WorkspaceWindowHistoryController>.value(value: runtime.workspaceWindowHistoryController),
        Provider<WorkspaceMediaImportController>.value(value: runtime.workspaceMediaImportController),
        Provider<WorkspaceWindowController>.value(value: runtime.workspaceWindowController),
        Provider<WorkspaceViewportSessionController>.value(value: runtime.workspaceViewportSessionController),
        Provider<WorkspaceCollateController>.value(value: runtime.workspaceCollateController),
        Provider<WorkspaceVideoConversionController>.value(value: runtime.workspaceVideoConversionController),
        Provider<WorkspaceAssetPickerController>.value(value: runtime.workspaceAssetPickerController),
        Provider<WorkspaceShortcutController>.value(value: runtime.workspaceShortcutController),
      ],
      child: child,
    );
  }
}

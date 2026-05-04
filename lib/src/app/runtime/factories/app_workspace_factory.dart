import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part 'app_workspace_factory_scope.dart';
part 'app_workspace_factory_core.dart';
part 'app_workspace_factory_environment.dart';
part 'app_workspace_factory_media.dart';

AppWorkspaceServices createAppWorkspaceServices({required AppRuntimeInputs inputs, required AppFoundation foundation}) {
  final scope = _WorkspaceFactoryScope(
    inputs: inputs,
    foundation: foundation,
  );

  final thumbnailController = _createThumbnailController(scope: scope);
  final workspaceLinksController = _createWorkspaceLinksController(scope: scope);
  final workspaceLinksLauncher = _createWorkspaceLinksLauncher(scope: scope);
  final workspaceLinksPrompts = _createWorkspaceLinksPrompts(scope: scope);
  final workspaceController = _createWorkspaceController(scope: scope, thumbnailController: thumbnailController);
  final workspaceWindowController = _createWorkspaceWindowController(
    scope: scope,
    workspaceController: workspaceController,
  );
  final workspaceWindowHistoryController = _createWorkspaceWindowHistoryController(
    scope: scope,
    workspaceController: workspaceController,
  );
  final workspaceViewportSessionController = _createWorkspaceViewportSessionController(
    scope: scope,
    thumbnailController: thumbnailController,
  );
  final workspaceCollateController = _createWorkspaceCollateController(
    scope: scope,
    workspaceWindowController: workspaceWindowController,
  );
  final environmentNavigationController = _createEnvironmentNavigationController(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final workspaceExposeLayoutController = _createWorkspaceExposeLayoutController(scope: scope);
  final environmentManagementController = _createEnvironmentManagementController(
    scope: scope,
    navigationController: environmentNavigationController,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final environmentController = EnvironmentController(
    navigation: environmentNavigationController,
    management: environmentManagementController,
  );
  final workspaceShortcutController = _createWorkspaceShortcutController(
    scope: scope,
    navigationController: environmentNavigationController,
    workspaceLinksController: workspaceLinksController,
  );
  final workspaceViewTrackingController = _createWorkspaceViewTrackingController(scope: scope);
  final videoFrameExporter = VideoFrameExporter(mediaInspector: scope.media);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: scope.app.context);
  final workspaceVideoConversionController = _createWorkspaceVideoConversionController(
    scope: scope,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: workspaceVideoConversionPrompts,
  );
  final workspaceMediaImportController = _createWorkspaceMediaImportController(
    scope: scope,
    thumbnailController: thumbnailController,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: workspaceVideoConversionPrompts,
  );
  final workspaceAssetPickerController = _createWorkspaceAssetPickerController(
    workspaceMediaImportController: workspaceMediaImportController,
  );

  return AppWorkspaceServices(
    thumbnailController: thumbnailController,
    workspaceAssetPickerController: workspaceAssetPickerController,
    workspaceCollateController: workspaceCollateController,
    workspaceMediaImportController: workspaceMediaImportController,
    workspaceLinksController: workspaceLinksController,
    workspaceLinksLauncher: workspaceLinksLauncher,
    workspaceLinksPrompts: workspaceLinksPrompts,
    workspaceController: workspaceController,
    workspaceWindowController: workspaceWindowController,
    workspaceWindowHistoryController: workspaceWindowHistoryController,
    workspaceViewportSessionController: workspaceViewportSessionController,
    environmentController: environmentController,
    workspaceExposeLayoutController: workspaceExposeLayoutController,
    workspaceShortcutController: workspaceShortcutController,
    workspaceViewTrackingController: workspaceViewTrackingController,
    workspaceVideoConversionController: workspaceVideoConversionController,
  );
}

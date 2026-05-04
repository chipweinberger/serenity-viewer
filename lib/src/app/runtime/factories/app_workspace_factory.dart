import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_core.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_environment.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_media.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

AppWorkspaceServices createAppWorkspaceServices({required AppRuntimeInputs inputs, required AppFoundation foundation}) {
  final scope = WorkspaceFactoryScope(
    inputs: inputs,
    foundation: foundation,
  );

  final thumbnailController = createThumbnailController(scope: scope);
  final workspaceLinksController = createWorkspaceLinksController(scope: scope);
  final workspaceLinksLauncher = createWorkspaceLinksLauncher(scope: scope);
  final workspaceLinksPrompts = createWorkspaceLinksPrompts(scope: scope);
  final workspaceController = createWorkspaceController(scope: scope, thumbnailController: thumbnailController);
  final workspaceWindowController = createWorkspaceWindowController(
    scope: scope,
    workspaceController: workspaceController,
  );
  final workspaceWindowHistoryController = createWorkspaceWindowHistoryController(
    scope: scope,
    workspaceController: workspaceController,
  );
  final workspaceViewportSessionController = createWorkspaceViewportSessionController(
    scope: scope,
    thumbnailController: thumbnailController,
  );
  final workspaceCollateController = createWorkspaceCollateController(
    scope: scope,
    workspaceWindowController: workspaceWindowController,
  );
  final environmentNavigationController = createEnvironmentNavigationController(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final workspaceExposeLayoutController = createWorkspaceExposeLayoutController(scope: scope);
  final environmentManagementController = createEnvironmentManagementController(
    scope: scope,
    navigationController: environmentNavigationController,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final environmentController = EnvironmentController(
    navigation: environmentNavigationController,
    management: environmentManagementController,
  );
  final workspaceViewTrackingController = createWorkspaceViewTrackingController(scope: scope);
  final videoFrameExporter = VideoFrameExporter(mediaInspector: scope.media);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: scope.app.context);
  final workspaceVideoConversionController = createWorkspaceVideoConversionController(
    scope: scope,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: workspaceVideoConversionPrompts,
  );
  final workspaceMediaImportController = createWorkspaceMediaImportController(
    scope: scope,
    thumbnailController: thumbnailController,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: workspaceVideoConversionPrompts,
  );
  final workspaceShortcutController = createWorkspaceShortcutController(
    scope: scope,
    navigationController: environmentNavigationController,
    workspaceLinksController: workspaceLinksController,
  );
  final workspaceAssetPickerController = createWorkspaceAssetPickerController(
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

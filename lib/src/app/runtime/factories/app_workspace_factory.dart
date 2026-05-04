import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_core.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_environment.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_media.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

({
  WorkspaceController workspaceController,
  EnvironmentController environmentController,
  EnvironmentWindowHistoryController environmentWindowHistoryController,
})
createAppWorkspaceServices({required WorkspaceFactoryInputs inputs}) {
  final scope = WorkspaceFactoryScope.fromInputs(inputs);

  final thumbnailController = createThumbnailController(scope: scope);
  final workspaceLinksController = createWorkspaceLinksController(scope: scope);
  final workspaceCoreControllers = createWorkspaceCoreControllers(
    scope: scope,
    thumbnailController: thumbnailController,
  );
  final workspaceWindowController = createWorkspaceWindowController(scope: scope, core: workspaceCoreControllers);
  final workspaceMediaServices = createWorkspaceMediaServices(scope: scope, thumbnailController: thumbnailController);
  final workspaceEnvironmentServices = createWorkspaceEnvironmentServices(
    scope: scope,
    thumbnailController: thumbnailController,
    exposeController: workspaceCoreControllers.expose,
    environmentController: workspaceCoreControllers.environment,
    workspaceLinksController: workspaceLinksController,
    workspaceWindowController: workspaceWindowController,
  );
  final environmentWindowHistoryController = createEnvironmentWindowHistoryController(
    scope: scope,
    environmentWindowHistoryState: inputs.environmentWindowHistoryState,
    core: workspaceCoreControllers,
  );
  final workspaceController = createWorkspaceController(
    core: workspaceCoreControllers,
    window: workspaceWindowController,
    media: workspaceMediaServices.media,
    layout: workspaceEnvironmentServices.layout,
    shortcuts: workspaceEnvironmentServices.shortcuts,
    links: workspaceLinksController,
    thumbnails: thumbnailController,
    tracking: workspaceEnvironmentServices.tracking,
  );

  return (
    workspaceController: workspaceController,
    environmentController: workspaceEnvironmentServices.environment,
    environmentWindowHistoryController: environmentWindowHistoryController,
  );
}

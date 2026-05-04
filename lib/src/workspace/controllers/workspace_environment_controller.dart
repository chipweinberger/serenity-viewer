import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_tabs_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_window_transfer_controller.dart';

class WorkspaceEnvironmentController {
  WorkspaceEnvironmentController()
    : tabs = const WorkspaceEnvironmentTabsController(),
      windowTransfer = const WorkspaceEnvironmentWindowTransferController();

  final WorkspaceEnvironmentTabsController tabs;
  final WorkspaceEnvironmentWindowTransferController windowTransfer;
}

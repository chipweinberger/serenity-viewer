import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_tabs.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_window_transfer.dart';

class WorkspaceEnvironmentController {
  WorkspaceEnvironmentController()
    : tabs = const WorkspaceEnvironmentTabsController(),
      windowTransfer = const WorkspaceEnvironmentWindowTransferController();

  final WorkspaceEnvironmentTabsController tabs;
  final WorkspaceEnvironmentWindowTransferController windowTransfer;
}

import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_tabs.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_window_transfer.dart';

class WorkspaceEnvironmentControllerState {
  WorkspaceEnvironmentControllerState()
    : tabs = const WorkspaceEnvironmentTabsState(),
      windowTransfer = const WorkspaceEnvironmentWindowTransferState();

  final WorkspaceEnvironmentTabsState tabs;
  final WorkspaceEnvironmentWindowTransferState windowTransfer;
}

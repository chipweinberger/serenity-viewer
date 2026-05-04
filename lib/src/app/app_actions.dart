import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_navigation_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';

class AppActions {
  AppActions({required this.context, required this.state, required this.foundation, required this.workspace}) {
    navigation = AppNavigationController(appUiController: foundation.appUiController);
    feedback = AppFeedbackController(
      context: context,
      environmentStoreState: state.environmentStoreState,
      updateEnvironment: environmentStore.updateEnvironment,
    );
  }

  final BuildContext Function() context;
  final AppStateServices state;
  final AppFoundation foundation;
  final AppWorkspaceServices workspace;
  late final AppNavigationController navigation;
  late final AppFeedbackController feedback;

  EnvironmentStore get environmentStore {
    return foundation.environmentStore;
  }

  AppUiController get appUi {
    return foundation.appUiController;
  }
}

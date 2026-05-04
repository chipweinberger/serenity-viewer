import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_derived_state.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/media_import_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_navigation_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';

class AppActions {
  AppActions({
    required this.context,
    required this.imageExtensions,
    required this.videoExtensions,
    required this.state,
    required this.derived,
    required this.foundation,
    required this.documents,
    required this.workspace,
  }) {
    navigation = AppNavigationController(appUiController: foundation.appUiController);
    feedback = AppFeedbackController(
      context: context,
      environmentStoreState: state.environmentStoreState,
      updateEnvironment: environmentStore.updateEnvironment,
    );
    mediaImport = MediaImportController(
      imageExtensions: imageExtensions,
      videoExtensions: videoExtensions,
      environmentStoreState: state.environmentStoreState,
      activeWorkspace: () => derived.activeWorkspace,
      videoConversionCoordinator: workspace.videoConversionCoordinator,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      mediaBridge: foundation.mediaBridge,
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
      updateEnvironment: environmentStore.updateEnvironment,
      thumbnailController: workspace.thumbnailController,
      showMessage: feedback.showMessage,
    );
  }

  final BuildContext Function() context;
  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final AppStateServices state;
  final AppDerivedState derived;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  late final AppNavigationController navigation;
  late final AppFeedbackController feedback;
  late final MediaImportController mediaImport;

  EnvironmentStore get environmentStore {
    return foundation.environmentStore;
  }

  AppUiController get appUi {
    return foundation.appUiController;
  }
}

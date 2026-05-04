import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/app/app_root.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';

class AppFoundation {
  const AppFoundation({
    required this.mediaInspector,
    required this.platformBridge,
    required this.sharedVideoControllerPool,
    required this.environmentBookmarkSynchronizer,
  });

  final MediaInspector mediaInspector;
  final PlatformBridge platformBridge;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
}

AppFoundation createAppFoundation({
  required AppRootObjects rootObjects,
  required bool isRunningInWidgetTest,
  required String Function() windowTitle,
  required ValueChanged<String> showMessage,
  required bool Function() mounted,
}) {
  final mediaInspector = MediaInspector(isRunningInWidgetTest: isRunningInWidgetTest);
  final platformBridge = PlatformBridge(
    environmentStoreState: rootObjects.environmentStoreState,
    isRunningInWidgetTest: isRunningInWidgetTest,
    windowTitle: windowTitle,
    showMessage: showMessage,
    isMounted: mounted,
  );
  final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
    createFileBookmark: platformBridge.createFileBookmark,
  );

  return AppFoundation(
    mediaInspector: mediaInspector,
    platformBridge: platformBridge,
    sharedVideoControllerPool: SharedVideoControllerPool(),
    environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
  );
}

import 'package:file_selector/file_selector.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';

class WorkspaceMediaController {
  const WorkspaceMediaController({required this.importController, required this.videoConversionController});

  final WorkspaceMediaImportController importController;
  final WorkspaceVideoConversionController videoConversionController;

  List<XTypeGroup> get acceptedTypeGroups => importController.acceptedTypeGroups;

  Future<void> importFiles(List<XFile> files) {
    return importController.importFiles(files);
  }

  Future<void> pickAndImportAssets() async {
    final files = await openFiles(acceptedTypeGroups: acceptedTypeGroups);
    await importFiles(files);
  }

  Future<void> pickAndImportFolder() async {
    final directoryPath = await getDirectoryPath();
    if (directoryPath == null) {
      return;
    }
    await importFiles([XFile(directoryPath)]);
  }

  Future<void> convertWindowToJpeg(String windowId) {
    return videoConversionController.convertWindowToJpeg(windowId);
  }

  bool isConvertibleWindow(Window? window) {
    return videoConversionController.isConvertibleWindow(window);
  }

  bool hasConvertibleWindows(Iterable<String> windowIds) {
    return videoConversionController.hasConvertibleWindows(windowIds);
  }

  Future<void> convertWindowsToJpeg(List<String> windowIds) {
    return videoConversionController.convertWindowsToJpeg(windowIds);
  }
}

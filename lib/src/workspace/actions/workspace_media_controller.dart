import 'package:file_selector/file_selector.dart';

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

  Future<void> convertVideoWindowToJpeg(String windowId) {
    return videoConversionController.convertVideoWindowToJpeg(windowId);
  }
}

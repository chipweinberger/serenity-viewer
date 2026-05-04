import 'package:file_selector/file_selector.dart';

class WorkspaceAssetPickerController {
  const WorkspaceAssetPickerController({required this.acceptedTypeGroups, required this.importFiles});

  final List<XTypeGroup> Function() acceptedTypeGroups;
  final Future<void> Function(List<XFile> files) importFiles;

  Future<void> pickAndImportAssets() async {
    final files = await openFiles(acceptedTypeGroups: acceptedTypeGroups());
    await importFiles(files);
  }
}

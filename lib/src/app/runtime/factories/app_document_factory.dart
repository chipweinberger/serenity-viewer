import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

DocumentCoordinator createAppDocumentCoordinator({
  required EnvironmentStore environmentStore,
  required DocumentUiActions ui,
  required DocumentLoadActions load,
  required DocumentSaveActions save,
  required DocumentCreationActions creation,
  required DocumentThumbnailActions thumbnails,
}) {
  return DocumentCoordinator(
    environmentStore: environmentStore,
    ui: ui,
    load: load,
    save: save,
    creation: creation,
    thumbnails: thumbnails,
  );
}

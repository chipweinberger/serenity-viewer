import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:serenity_viewer/src/environment/link.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class WorkspaceLinksLauncher {
  const WorkspaceLinksLauncher({required this.showMessage, required this.mounted});

  final ValueChanged<String> showMessage;
  final bool Function() mounted;

  Future<void> openLink(Link link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      showMessage('That link is invalid.');
      return;
    }

    final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!didLaunch && mounted()) {
      showMessage('Could not open that link.');
    }
  }

  Future<void> openAllLinks(Workspace workspace) async {
    if (workspace.links.isEmpty) {
      showMessage('There are no links to open.');
      return;
    }

    var openedCount = 0;
    for (final link in workspace.links) {
      final uri = Uri.tryParse(link.url);
      if (uri == null) {
        continue;
      }
      final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (didLaunch) {
        openedCount += 1;
      }
    }

    if (!mounted()) {
      return;
    }

    if (openedCount == 0) {
      showMessage('Could not open any links.');
      return;
    }

    if (openedCount < workspace.links.length) {
      showMessage('Opened $openedCount of ${workspace.links.length} links.');
      return;
    }

    showMessage('Opened all ${workspace.links.length} links.');
  }
}

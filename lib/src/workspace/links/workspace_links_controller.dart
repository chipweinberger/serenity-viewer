import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/link.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_link_parser.dart';

class WorkspaceLinksController {
  WorkspaceLinksController({
    required this.screen,
    required this.hasSession,
    required this.activeWorkspace,
    required this.workspaces,
    required this.replaceWorkspace,
    required this.newId,
    required this.showMessage,
    required this.mounted,
  });

  final SerenityScreen Function() screen;
  final bool Function() hasSession;
  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final ValueChanged<Workspace> replaceWorkspace;
  final String Function(String prefix) newId;
  final ValueChanged<String> showMessage;
  final bool Function() mounted;

  bool shouldHandlePasteLinksShortcut(KeyDownEvent event) {
    if (screen() != SerenityScreen.workspace || !hasSession()) {
      return false;
    }
    if (_isTextInputFocused()) {
      return false;
    }
    final key = event.logicalKey;
    final isPasteKey = key == LogicalKeyboardKey.keyV;
    final hasModifier = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    return isPasteKey && hasModifier;
  }

  Future<void> pasteLinksFromClipboard() async {
    final workspace = activeWorkspace();
    if (workspace == null) {
      return;
    }

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();
    if (text == null || text.isEmpty) {
      showMessage('Clipboard does not contain any text.');
      return;
    }

    final addedCount = addLinksFromText(workspace.id, text);
    if (addedCount == 0) {
      showMessage('No new URLs were found in that text.');
    }
  }

  int addLinksFromText(String workspaceId, String text) {
    final matches = WorkspaceLinkParser.extractUrls(text);
    if (matches.isEmpty) {
      return 0;
    }

    final workspace = workspaceForId(workspaceId);
    if (workspace == null) {
      return 0;
    }

    final existingUrls = workspace.links.map((link) => link.url).toSet();
    final nextLinks = [...workspace.links];
    var addedCount = 0;

    for (final url in matches) {
      if (existingUrls.contains(url)) {
        continue;
      }
      existingUrls.add(url);
      nextLinks.add(Link(id: newId('link'), url: url));
      addedCount += 1;
    }

    if (addedCount == 0) {
      return 0;
    }

    replaceWorkspace(workspace.copyWith(links: nextLinks));
    showMessage('Added $addedCount link${addedCount == 1 ? '' : 's'} to ${workspace.name}.');
    return addedCount;
  }

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

  Workspace? removeLink(String workspaceId, String linkId) {
    final workspace = workspaceForId(workspaceId);
    if (workspace == null) {
      return null;
    }

    final nextLinks = workspace.links.where((link) => link.id != linkId).toList();
    if (nextLinks.length == workspace.links.length) {
      return workspace;
    }

    final nextWorkspace = workspace.copyWith(links: nextLinks);
    replaceWorkspace(nextWorkspace);
    return nextWorkspace;
  }

  Workspace? renameLink(String workspaceId, String linkId, String customName) {
    final workspace = workspaceForId(workspaceId);
    if (workspace == null) {
      return null;
    }

    var changed = false;
    final normalizedName = customName.trim();
    final nextLinks = workspace.links.map((link) {
      if (link.id != linkId) {
        return link;
      }
      changed = true;
      return link.copyWith(customName: normalizedName);
    }).toList();

    if (!changed) {
      return workspace;
    }

    final nextWorkspace = workspace.copyWith(links: nextLinks);
    replaceWorkspace(nextWorkspace);
    return nextWorkspace;
  }

  Workspace? workspaceForId(String workspaceId) {
    return workspaces().where((entry) => entry.id == workspaceId).firstOrNull;
  }

  String middleTruncatedLabel(String value, {int maxLength = 42}) {
    if (value.length <= maxLength) {
      return value;
    }

    final available = maxLength - 1;
    final leadingLength = (available / 2).ceil();
    final trailingLength = (available / 2).floor();
    return '${value.substring(0, leadingLength)}…${value.substring(value.length - trailingLength)}';
  }

  bool _isTextInputFocused() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) {
      return false;
    }
    return focusedContext.widget is EditableText ||
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}

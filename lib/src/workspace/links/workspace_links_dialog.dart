import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/link.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';

Future<void> showWorkspaceLinksDialog({
  required BuildContext context,
  required Workspace initialWorkspace,
  required WorkspaceLinksController controller,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Workspace links',
    barrierColor: Colors.black.withValues(alpha: 0.26),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _WorkspaceLinksDialog(initialWorkspace: initialWorkspace, controller: controller);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curve), child: child),
      );
    },
  );
}

class _WorkspaceLinksDialog extends StatefulWidget {
  const _WorkspaceLinksDialog({required this.initialWorkspace, required this.controller});

  final Workspace initialWorkspace;
  final WorkspaceLinksController controller;

  @override
  State<_WorkspaceLinksDialog> createState() => _WorkspaceLinksDialogState();
}

class _WorkspaceLinksDialogState extends State<_WorkspaceLinksDialog> {
  late Workspace _workspace;
  final TextEditingController _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _workspace = widget.initialWorkspace;
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _syncWorkspace(Workspace? workspace) {
    if (workspace == null) {
      return;
    }
    setState(() {
      _workspace = workspace;
    });
  }

  Future<void> _openLink(Link link) async {
    await widget.controller.openLink(link);
  }

  Future<void> _renameLink(Link link) async {
    final customName = await widget.controller.promptForLinkName(link);
    if (customName == null) {
      return;
    }
    _syncWorkspace(widget.controller.renameLink(_workspace.id, link.id, customName));
  }

  Future<void> _removeLink(Link link) async {
    final shouldRemove = await widget.controller.confirmRemoveLink(link);
    if (!shouldRemove) {
      return;
    }
    _syncWorkspace(widget.controller.removeLink(_workspace.id, link.id));
  }

  void _handleComposerChanged(String value) {
    final addedCount = widget.controller.addLinksFromText(_workspace.id, value);
    if (addedCount == 0) {
      return;
    }

    _syncWorkspace(widget.controller.workspaceForId(_workspace.id));
    _pasteController.clear();
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
      child: TextField(
        controller: _pasteController,
        autofocus: _workspace.links.isEmpty,
        maxLines: 1,
        minLines: 1,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        onChanged: _handleComposerChanged,
        decoration: InputDecoration(
          hintText: 'Paste links here',
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: AppTheme.textMuted.withValues(alpha: 0.9), height: 1.0),
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppTheme.textPrimary, height: 1.0),
      ),
    );
  }

  Widget _buildLinkRow(Link link) {
    final displayTitle = link.hasCustomName
        ? link.trimmedCustomName
        : widget.controller.middleTruncatedLabel(link.url, maxLength: 54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openLink(link),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Name link',
            onPressed: () => _renameLink(link),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Remove link',
            onPressed: () => _removeLink(link),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_workspace.links.length} Link${_workspace.links.length == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall!.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: _workspace.links.isEmpty
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.34),
              child: InkWell(
                onTap: _workspace.links.isEmpty ? null : () => unawaited(widget.controller.openAllLinks(_workspace)),
                child: SizedBox(
                  height: 32,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: _workspace.links.isEmpty
                            ? AppTheme.textMuted.withValues(alpha: 0.6)
                            : const Color(0xFF4C78C8),
                        fontWeight: FontWeight.w600,
                      ),
                      child: const Center(child: Text('Open All')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.white.withValues(alpha: 0.34),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _workspace.links.isEmpty
          ? Center(
              key: const ValueKey('empty-links'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Paste a URL above to keep it with this workspace.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppTheme.textMuted, height: 1.4),
                ),
              ),
            )
          : ListView.separated(
              key: const ValueKey('links-list'),
              padding: EdgeInsets.zero,
              itemCount: _workspace.links.length,
              itemBuilder: (context, index) => _buildLinkRow(_workspace.links[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = math.min(560.0, screenWidth - 36);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                width: dialogWidth,
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 36, offset: const Offset(0, 18)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildComposer(),
                      const SizedBox(height: 14),
                      Expanded(child: _buildLinksList()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

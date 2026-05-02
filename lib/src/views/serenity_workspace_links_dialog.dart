part of '../../main.dart';

extension _SerenityShellWorkspaceLinksDialog on _SerenityShellState {
  Future<void> _openWorkspaceLinksDialog(WorkspaceState initialWorkspace) async {
    var workspace = initialWorkspace;
    final pasteController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Workspace links',
      barrierColor: Colors.black.withValues(alpha: 0.26),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return StatefulBuilder(
              builder: (context, setLocalState) {
                final availableWidth = math.max(280.0, constraints.maxWidth - 48);
                final availableHeight = math.max(220.0, constraints.maxHeight - 48);
                final dialogWidth = math.min(620.0, availableWidth);
                final dialogHeight = math.min(760.0, availableHeight);

                Widget buildComposer() {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
                    ),
                    child: TextField(
                      controller: pasteController,
                      autofocus: workspace.links.isEmpty,
                      maxLines: 1,
                      minLines: 1,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (value) {
                        final addedCount = _addLinksFromText(workspace.id, value);
                        if (addedCount == 0) {
                          return;
                        }
                        setLocalState(() {
                          workspace = _workspaces.firstWhere((entry) => entry.id == workspace.id);
                        });
                        pasteController.clear();
                      },
                      decoration: InputDecoration(
                        hintText: 'Paste links here',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: SerenityTheme.textMuted.withValues(alpha: 0.9),
                          height: 1.0,
                        ),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: SerenityTheme.textPrimary, height: 1.0),
                    ),
                  );
                }

                Widget buildLinkRow(WorkspaceLink link) {
                  final displayTitle = link.hasCustomName
                      ? link.trimmedCustomName
                      : _middleTruncatedLabel(link.url, maxLength: 54);
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
                            onTap: () async {
                              await _openWorkspaceLink(link);
                            },
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
                                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                      color: SerenityTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    link.url,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall!.copyWith(color: SerenityTheme.textMuted, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Name link',
                          onPressed: () async {
                            final customName = await _promptForWorkspaceLinkName(link);
                            if (customName == null) {
                              return;
                            }
                            final updatedWorkspace = _renameWorkspaceLink(workspace.id, link.id, customName);
                            if (updatedWorkspace == null) {
                              return;
                            }
                            setLocalState(() {
                              workspace = updatedWorkspace;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Remove link',
                          onPressed: () async {
                            final shouldRemove = await _confirmRemoveWorkspaceLink(link);
                            if (!shouldRemove) {
                              return;
                            }
                            final updatedWorkspace = _removeWorkspaceLink(workspace.id, link.id);
                            if (updatedWorkspace == null) {
                              return;
                            }
                            setLocalState(() {
                              workspace = updatedWorkspace;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  );
                }

                return SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.2),
                            child: SizedBox(
                              width: dialogWidth,
                              height: dialogHeight,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.58),
                                      const Color(0xFFF3E3CD).withValues(alpha: 0.44),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                                  boxShadow: const [
                                    BoxShadow(color: SerenityTheme.shadow, blurRadius: 40, offset: Offset(0, 16)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${workspace.links.length} Link${workspace.links.length == 1 ? '' : 's'}',
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                              color: SerenityTheme.textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: BackdropFilter(
                                            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                            child: Material(
                                              color: workspace.links.isEmpty
                                                  ? Colors.white.withValues(alpha: 0.18)
                                                  : Colors.white.withValues(alpha: 0.34),
                                              child: InkWell(
                                                onTap: workspace.links.isEmpty
                                                    ? null
                                                    : () => unawaited(_openAllWorkspaceLinks(workspace)),
                                                child: SizedBox(
                                                  height: 32,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: DefaultTextStyle(
                                                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                                        color: workspace.links.isEmpty
                                                            ? SerenityTheme.textMuted.withValues(alpha: 0.6)
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
                                                  child: Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                    color: SerenityTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    buildComposer(),
                                    const SizedBox(height: 18),
                                    Expanded(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 180),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        child: workspace.links.isEmpty
                                            ? Center(
                                                key: const ValueKey('empty-links'),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 36),
                                                  child: Text(
                                                    'No links yet.',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium!.copyWith(color: SerenityTheme.textMuted),
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                key: const ValueKey('links-list'),
                                                itemBuilder: (context, index) => buildLinkRow(workspace.links[index]),
                                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                                itemCount: workspace.links.length,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curve), child: child),
        );
      },
    );

    pasteController.dispose();
  }
}

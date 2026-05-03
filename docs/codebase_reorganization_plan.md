# Codebase Reorganization Plan

## Goal

Reorganize Serenity around product domains and user flows instead of abstract layers like `models`, `views`, `widgets`, `state`, and `persistence`.

A new engineer should be able to answer these questions from the tree alone:

- Where do I go for workspace window behavior?
- Where do I go for playback?
- Where do I go for importing media?
- Where do I go for setup and environment loading?
- Where do I go for device and app settings?

## What The Current Tree Is Telling Us

Today the code is mostly grouped by technical role:

- `lib/src/app`
- `lib/src/models`
- `lib/src/state`
- `lib/src/views`
- `lib/src/widgets`
- `lib/src/persistence`
- `lib/src/media`

That split makes one product concept span many folders. A single change to “workspace windows” can require touching:

- workspace mutations in `app`
- workspace or window data in `models`
- viewport and interaction flags in `state`
- layout and screen code in `views`
- actual window rendering in `widgets`

The strongest smell is [`lib/src/app/serenity_shell.dart`](/Volumes/User/serenity-viewer/lib/src/app/serenity_shell.dart), which imports nearly every conceptual area and uses `part` files to reach across multiple folders. The product already has clear domains; the file structure just does not reflect them.

## Recommended Shape

Keep `lib/main.dart` as the entrypoint, then reorganize `lib/src` like this:

```text
lib/
  main.dart
  src/
    app/
      serenity_app.dart
      shell/
        serenity_shell.dart
        shell_dependencies.dart
        shell_menu_actions.dart
        shell_window_title.dart

    features/
      workspace/
        workspace_screen.dart
        workspace_controller.dart
        workspace_state.dart
        workspace_mutations.dart
        workspace_projection.dart
        workspace_layout_mode.dart
        workspace_hud.dart
        workspace_chrome_overlay.dart
        workspace_links_dialog.dart
        workspace_links_controller.dart
        workspace_thumbnail_card.dart
        workspace_view_tracking_state.dart
        workspace_viewport_state.dart
        viewport/
          workspace_geometry.dart
          workspace_window_geometry.dart
        expose/
          expose_window_card.dart
          workspace_layouts.dart
        windows/
          workspace_window.dart
          window_frame.dart
          window_frame_chrome.dart
          window_frame_content.dart
          window_frame_interactions.dart
          window_frame_presentation.dart
          window_overlay.dart
          window_resize_helpers.dart
          window_interaction_state.dart
          recently_closed_window_entry.dart
          window_zoom_update.dart

      library/
        library_screen.dart
        library_view.dart

      media/
        assets/
          workspace_asset.dart
          media_counts.dart
          media_placeholders.dart
          image_surface.dart
          video_surface.dart
          media_canvas.dart
          media_preview_transforms.dart
          media_zoom_utils.dart
          missing_asset_resolution.dart
        importing/
          import_coordinator.dart
          import_result.dart
          import_and_load_plan.dart
          import_window_planning.dart
        playback/
          media_bridge.dart
          workspace_load_plan.dart
          load_plan.dart
        video_conversion/
          video_conversion_coordinator.dart
          session_support.dart

      environments/
        environment_coordinator.dart
        environment_archive.dart
        session_state.dart
        session_controller.dart
        session_persistence_bridge.dart
        shell_persistence_state.dart
        thumbnail_refresh_state.dart
        startup/
          seed_and_settings.dart

      settings/
        settings_dialog.dart
        chrome_state.dart
        shell_ui_state.dart
        theme/
          serenity_theme.dart

    shared/
      navigation/
      platform/
      utils/
      ids/

    foundation/
      serenity_core.dart
      keyboard_modifiers.dart
```

## Why This Structure Fits Serenity

- `workspace` is the center of the product. The floating desktop metaphor, viewport math, expose mode, links, thumbnails, and window chrome all belong there.
- `library` is its own user flow. It is not just “a view”; it is the browse/search/open workspace experience.
- `media` is a real system concept. Importing, loading, placeholder handling, image surfaces, video surfaces, and playback coordination all revolve around media behavior.
- `environments` is another real system concept. Session restore, `.sry` import/export, startup behavior, and persistence all belong together.
- `settings` should hold user-facing configuration and shell-level UI preferences, not be scattered between `app`, `state`, and `widgets`.
- `shared` stays intentionally small and only holds truly reusable infrastructure.
- `foundation` keeps low-level enums and app-wide primitives that are genuinely global.

## Folder Rules

- Use product nouns first: `workspace`, `library`, `media`, `environments`, `settings`.
- Keep files flat inside a feature until that feature gets large.
- When a feature grows, split into meaningful subareas like `windows`, `viewport`, `importing`, or `playback`.
- Do not recreate global `models`, `widgets`, or `views` folders inside `features`.
- Keep behavior that changes together in the same folder, even if it mixes UI, state, and orchestration.
- Prefer literal names over abstract names. Example: `workspace_window.dart` is easier to place than `asset_window_state.dart`.

## Suggested Renames

These are worth renaming during the move because the current names expose implementation shape more than product meaning.

- `asset_window_state.dart` -> `workspace_window.dart`
- `serenity_load_plan.dart` -> `load_plan.dart`
- `serenity_workspace_load_plan.dart` -> `workspace_load_plan.dart`
- `serenity_media_bridge.dart` -> `media_bridge.dart`
- `serenity_import_coordinator.dart` -> `import_coordinator.dart`
- `serenity_environment_coordinator.dart` -> `environment_coordinator.dart`
- `serenity_session_persistence_bridge.dart` -> `session_persistence_bridge.dart`
- `serenity_shell_persistence_state.dart` -> `shell_persistence_state.dart`
- `workspace_media_counts.dart` -> `media_counts.dart`

## File Migration Map

### App bootstrap

- `lib/src/app/serenity_shell.dart` -> `lib/src/app/shell/serenity_shell.dart`
- `lib/src/app/serenity_shell_dependencies.dart` -> `lib/src/app/shell/shell_dependencies.dart`
- `lib/src/app/serenity_menus.dart` -> `lib/src/app/shell/shell_menu_actions.dart`

### Workspace domain

- `lib/src/app/serenity_workspace_controller.dart` -> `lib/src/features/workspace/workspace_controller.dart`
- `lib/src/app/serenity_workspace_mutations.dart` -> `lib/src/features/workspace/workspace_mutations.dart`
- `lib/src/app/serenity_workspace_mutations_session.dart` -> `lib/src/features/workspace/workspace_mutations_session.dart`
- `lib/src/app/serenity_workspace_mutations_viewport.dart` -> `lib/src/features/workspace/workspace_mutations_viewport.dart`
- `lib/src/app/serenity_workspace_mutations_window.dart` -> `lib/src/features/workspace/workspace_mutations_window.dart`
- `lib/src/app/serenity_workspace_geometry.dart` -> `lib/src/features/workspace/viewport/workspace_geometry.dart`
- `lib/src/app/serenity_workspace_window_geometry.dart` -> `lib/src/features/workspace/viewport/workspace_window_geometry.dart`
- `lib/src/app/serenity_workspace_management.dart` -> `lib/src/features/workspace/workspace_management.dart`
- `lib/src/app/serenity_workspace_views.dart` -> `lib/src/features/workspace/workspace_views.dart`
- `lib/src/app/serenity_workspace_links_controller.dart` -> `lib/src/features/workspace/workspace_links_controller.dart`
- `lib/src/models/workspace_state.dart` -> `lib/src/features/workspace/workspace_state.dart`
- `lib/src/models/workspace_link.dart` -> `lib/src/features/workspace/workspace_link.dart`
- `lib/src/models/asset_window_state.dart` -> `lib/src/features/workspace/windows/workspace_window.dart`
- `lib/src/models/recently_closed_window_entry.dart` -> `lib/src/features/workspace/windows/recently_closed_window_entry.dart`
- `lib/src/models/window_zoom_update.dart` -> `lib/src/features/workspace/windows/window_zoom_update.dart`
- `lib/src/models/serenity_workspace_canvas_view_model.dart` -> `lib/src/features/workspace/workspace_canvas_view_model.dart`
- `lib/src/models/serenity_workspace_chrome_view_model.dart` -> `lib/src/features/workspace/workspace_chrome_view_model.dart`
- `lib/src/models/serenity_window_frame_view_model.dart` -> `lib/src/features/workspace/windows/window_frame_view_model.dart`
- `lib/src/state/serenity_window_interaction_state.dart` -> `lib/src/features/workspace/windows/window_interaction_state.dart`
- `lib/src/state/serenity_workspace_view_tracking_state.dart` -> `lib/src/features/workspace/workspace_view_tracking_state.dart`
- `lib/src/state/serenity_workspace_viewport_state.dart` -> `lib/src/features/workspace/workspace_viewport_state.dart`
- `lib/src/views/serenity_workspace_screen.dart` -> `lib/src/features/workspace/workspace_screen.dart`
- `lib/src/views/serenity_workspace_hud.dart` -> `lib/src/features/workspace/workspace_hud.dart`
- `lib/src/views/serenity_workspace_chrome_overlay.dart` -> `lib/src/features/workspace/workspace_chrome_overlay.dart`
- `lib/src/views/serenity_workspace_layouts.dart` -> `lib/src/features/workspace/expose/workspace_layouts.dart`
- `lib/src/views/serenity_workspace_links_dialog.dart` -> `lib/src/features/workspace/workspace_links_dialog.dart`
- `lib/src/widgets/expose_window_card.dart` -> `lib/src/features/workspace/expose/expose_window_card.dart`
- `lib/src/widgets/serenity_window_frame.dart` -> `lib/src/features/workspace/windows/window_frame.dart`
- `lib/src/widgets/serenity_window_frame_chrome.dart` -> `lib/src/features/workspace/windows/window_frame_chrome.dart`
- `lib/src/widgets/serenity_window_frame_content.dart` -> `lib/src/features/workspace/windows/window_frame_content.dart`
- `lib/src/widgets/serenity_window_frame_interactions.dart` -> `lib/src/features/workspace/windows/window_frame_interactions.dart`
- `lib/src/widgets/serenity_window_frame_presentation.dart` -> `lib/src/features/workspace/windows/window_frame_presentation.dart`
- `lib/src/widgets/serenity_window_overlay.dart` -> `lib/src/features/workspace/windows/window_overlay.dart`
- `lib/src/widgets/window_resize_helpers.dart` -> `lib/src/features/workspace/windows/window_resize_helpers.dart`
- `lib/src/widgets/workspace_thumbnail_card.dart` -> `lib/src/features/workspace/workspace_thumbnail_card.dart`

### Library domain

- `lib/src/views/serenity_library_screen.dart` -> `lib/src/features/library/library_screen.dart`
- `lib/src/views/serenity_library_view.dart` -> `lib/src/features/library/library_view.dart`

### Media domain

- `lib/src/app/serenity_import_coordinator.dart` -> `lib/src/features/media/importing/import_coordinator.dart`
- `lib/src/app/serenity_import_result.dart` -> `lib/src/features/media/importing/import_result.dart`
- `lib/src/app/serenity_media_bridge.dart` -> `lib/src/features/media/playback/media_bridge.dart`
- `lib/src/app/serenity_video_conversion_coordinator.dart` -> `lib/src/features/media/video_conversion/video_conversion_coordinator.dart`
- `lib/src/media/serenity_import_and_load_plan.dart` -> `lib/src/features/media/importing/import_and_load_plan.dart`
- `lib/src/media/serenity_import_window_planning.dart` -> `lib/src/features/media/importing/import_window_planning.dart`
- `lib/src/media/serenity_missing_asset_resolution.dart` -> `lib/src/features/media/assets/missing_asset_resolution.dart`
- `lib/src/media/serenity_workspace_load_plan.dart` -> `lib/src/features/media/playback/workspace_load_plan.dart`
- `lib/src/models/workspace_asset.dart` -> `lib/src/features/media/assets/workspace_asset.dart`
- `lib/src/models/workspace_media_counts.dart` -> `lib/src/features/media/assets/media_counts.dart`
- `lib/src/models/serenity_load_plan.dart` -> `lib/src/features/media/playback/load_plan.dart`
- `lib/src/models/session_support.dart` -> `lib/src/features/media/video_conversion/session_support.dart`
- `lib/src/widgets/serenity_image_surface.dart` -> `lib/src/features/media/assets/image_surface.dart`
- `lib/src/widgets/serenity_video_surface.dart` -> `lib/src/features/media/assets/video_surface.dart`
- `lib/src/widgets/serenity_media_canvas.dart` -> `lib/src/features/media/assets/media_canvas.dart`
- `lib/src/widgets/serenity_media_placeholders.dart` -> `lib/src/features/media/assets/media_placeholders.dart`
- `lib/src/widgets/serenity_media_preview_transforms.dart` -> `lib/src/features/media/assets/media_preview_transforms.dart`
- `lib/src/widgets/serenity_media_zoom_utils.dart` -> `lib/src/features/media/assets/media_zoom_utils.dart`
- `lib/src/widgets/serenity_zoom_box.dart` -> `lib/src/features/media/assets/zoom_box.dart`

### Environment and persistence domain

- `lib/src/app/serenity_environment_coordinator.dart` -> `lib/src/features/environments/environment_coordinator.dart`
- `lib/src/app/serenity_session_controller.dart` -> `lib/src/features/environments/session_controller.dart`
- `lib/src/app/serenity_session_persistence_bridge.dart` -> `lib/src/features/environments/session_persistence_bridge.dart`
- `lib/src/app/serenity_session_actions.dart` -> `lib/src/features/environments/session_actions.dart`
- `lib/src/app/serenity_seed_and_settings.dart` -> `lib/src/features/environments/startup/seed_and_settings.dart`
- `lib/src/models/serenity_session_state.dart` -> `lib/src/features/environments/session_state.dart`
- `lib/src/persistence/serenity_environment_archive.dart` -> `lib/src/features/environments/environment_archive.dart`
- `lib/src/persistence/serenity_thumbnail_persistence.dart` -> `lib/src/features/environments/thumbnail_persistence.dart`
- `lib/src/state/serenity_shell_persistence_state.dart` -> `lib/src/features/environments/shell_persistence_state.dart`
- `lib/src/state/serenity_thumbnail_refresh_state.dart` -> `lib/src/features/environments/thumbnail_refresh_state.dart`

### Settings and shell UI

- `lib/src/app/serenity_chrome_controller.dart` -> `lib/src/features/settings/chrome_controller.dart`
- `lib/src/app/serenity_shell_ui_state.dart` -> `lib/src/features/settings/shell_ui_state.dart`
- `lib/src/widgets/serenity_settings_dialog.dart` -> `lib/src/features/settings/settings_dialog.dart`
- `lib/src/state/serenity_chrome_state.dart` -> `lib/src/features/settings/chrome_state.dart`
- `lib/src/core/serenity_theme.dart` -> `lib/src/features/settings/theme/serenity_theme.dart`

### Foundation and shared helpers

- `lib/src/core/serenity_core.dart` -> `lib/src/foundation/serenity_core.dart`
- `lib/src/core/serenity_keyboard_modifiers.dart` -> `lib/src/foundation/keyboard_modifiers.dart`
- `lib/src/core/serenity_workspace_projection.dart` -> `lib/src/features/workspace/workspace_projection.dart`
- `lib/src/widgets/serenity_glass_chip.dart` -> `lib/src/shared/ui/serenity_glass_chip.dart`
- `lib/src/widgets/serenity_demo_art.dart` -> `lib/src/shared/ui/serenity_demo_art.dart`

## One Important Structural Change

The `part` files hanging off `serenity_shell.dart` should be absorbed into the features they belong to.

Current `part` files:

- `serenity_session_actions.dart`
- `serenity_shell_ui_state.dart`
- `serenity_window_actions.dart`
- `serenity_window_history_actions.dart`
- `serenity_workspace_management.dart`
- `serenity_menus.dart`
- `serenity_seed_and_settings.dart`
- `serenity_workspace_views.dart`
- `serenity_workspace_geometry.dart`
- `serenity_library_view.dart`
- `serenity_thumbnail_persistence.dart`
- `serenity_import_and_load_plan.dart`

Recommended direction:

- replace `part` files with normal Dart files and explicit dependencies
- let each feature own its own actions and helpers
- make `SerenityShell` orchestrate features instead of containing hidden partial classes

## Migration Order

Do this in phases so the repo stays buildable.

### Phase 1: Create the new folders and move without behavior changes

- create `features/workspace`, `features/library`, `features/media`, `features/environments`, and `features/settings`
- move files into their new homes
- keep imports and class names stable at first where possible

### Phase 2: Remove cross-folder `part` dependencies

- convert `part` files to normal files
- inject explicit dependencies
- keep `SerenityShell` focused on app bootstrapping and top-level orchestration

### Phase 3: Rename files to literal product names

- rename files like `asset_window_state.dart` and `serenity_load_plan.dart`
- rename related types only when the resulting names are clearly better

### Phase 4: Shrink the shell

- move startup/environment code into `environments`
- move workspace-only actions into `workspace`
- move playback and import plumbing into `media`
- leave `SerenityShell` as the place that wires screens, menus, and shared app lifecycle concerns together

### Phase 5: Clean up leftover abstractions

- delete empty old folders
- collapse tiny wrappers that only existed to satisfy the old layered structure
- split large files only where readability actually improves

## What I Would Not Do

- I would not create `domain`, `data`, and `presentation` subfolders inside every feature.
- I would not preserve a repo-wide `models` folder.
- I would not keep all widgets globally grouped.
- I would not over-normalize small support files into deep hierarchies.
- I would not move shared code into `shared` unless multiple product areas genuinely depend on it.

## Recommended First Pass

If we do this for real, I would start with these five moves first because they give the biggest navigation win immediately:

- create `features/workspace` and move all workspace, window, expose, viewport, and link code there
- create `features/media` and move import, playback, surfaces, placeholders, and asset definitions there
- create `features/environments` and move session plus `.sry` persistence there
- move the library files into `features/library`
- reduce `app` to bootstrapping and shell orchestration only

## End State

After the reorg, a new engineer should be able to navigate by asking:

- “I need to change how windows move or resize” -> `features/workspace/windows`
- “I need to change the canvas, viewport, or expose mode” -> `features/workspace`
- “I need to change workspace browsing” -> `features/library`
- “I need to change import, playback, or media loading” -> `features/media`
- “I need to change `.sry` files, startup restore, or autosave” -> `features/environments`
- “I need to change settings or shell chrome behavior” -> `features/settings`

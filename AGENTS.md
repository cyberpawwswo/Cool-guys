# AGENTS.md

Godot 4.7 3D game (GDScript) — game-jam style, no build/test/lint tooling. Verify changes by running the project in the Godot 4.7 editor or `godot --path .` (imports/parse errors show on load; there are no automated tests).

## Key facts

- **Language is GDScript only.** `project.godot` has a `[dotnet]` section but there is no `.csproj` or C# code — do not add C#.
- **Scene flow:** main scene is `scenes/ui/main_menu/main_menu.tscn`; it loads `scenes/levels/test_level/test_level.tscn`. Pause menu (`scenes/ui/pause_menu/PauseMenu.tscn`) uses `process_mode = PROCESS_MODE_ALWAYS` and toggles `get_tree().paused` on `ui_cancel` (Esc).
- **Player & combat live in one script:** `scenes/player/player.gd` (CharacterBody3D). Headbutt/attack is a RayCast3D impulse applied to `RigidBody3D` colliders, triggered in `_process` via the `attack` action.
- **Input actions are defined in `project.godot`, not in code:** WASD move, Space jump, Shift sprint, Ctrl dash, LMB attack (headbutt). `strong_attack` (F) is mapped but unused. Add/rename actions in `project.godot`, not in scripts.
- **UIDs:** Godot 4.4+ references scenes/scripts by `uid://` and committed `.gd.uid` files. Never hand-edit UIDs; when moving/renaming a scene or script, use the editor so UIDs and `uid://` references update — manual renames silently break references.
- **`.import` files and `.gd.uid` files are committed.** Only `.godot/` and `/android/` are gitignored.
- **Conventions:** commit messages and some code comments are in Russian — match the language of the surrounding code/comment. Scripts use tabs, snake_case, `_`-prefixed private members.

## Layout

- `scenes/` — grouped by domain: `levels/`, `player/`, `ui/`, `weapons/` (each scene has a matching `.gd` script beside it)
- `materials/`, `materials/textures/` — materials and textures
- `addons/godot-prototype-texture/` — plain checker/grid texture assets, not an active plugin

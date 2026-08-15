# AGENTS.md

Godot 4.7 3D game (GDScript), GL Compatibility renderer + Jolt physics — game-jam style, no lint/build tooling. Verify changes by loading the project in the Godot 4.7 editor or `godot --path .` (imports/parse errors show on load). One integration test exists — see Testing.

## Key facts

- **GDScript only.** `project.godot` has a `[dotnet]` section but there is no `.csproj` or C# code — do not add C#. (`addons/voronoishatter/CSVoronoiAdapter/*.cs` is vendored dead code that cannot compile without a csproj.)
- **Input actions are defined in `project.godot`, not in code:** WASD move, Space jump, Shift sprint, Ctrl dash, LMB `attack`, F `strong_attack` (headbutt), H `black_white` (toggles the dark B/W mode — grayscale filter + dark blink + world darkness). Exception: weapon switching (1–3, mouse wheel) and reload (R) are hardcoded `physical_keycode` checks in `weapon_manager.gd:handle_input()`, not InputMap actions. Add/rename actions in `project.godot`.
- **Two visual modes toggled by H:** normal (bright world, textures visible, no filter) and dark B/W (world materials go near-black so textures hide, sky/light dim, `RigidBody3D`/player meshes glow white via the `glow_body` group, grayscale screen filter + dark blink every second). The player (`player.gd:_toggle_black_white_mode`) toggles the grayscale/blink and calls `DarkMode.set_dark_mode()` on the current level (`scenes/levels/test_level/dark_mode.gd`).
- **Player & combat live in `scenes/player/player.gd`** (CharacterBody3D). LMB (`attack`) calls `weapon_manager.play_attack()` (viewmodel anim/cooldown) then `_perform_attack()`: a RayCast3D impulse on `RigidBody3D` colliders; also zeroes `body.hp` if the collider has that property. F (`strong_attack`) is the headbutt — a timed windup whose strike `_perform_attack(true)` only hits within `close_distance`.
- **Weapons are viewmodel-only:** `scenes/player/weapon_manager.gd` hardcodes `WEAPON_DATA` (Boomstick / Beretta / Leg Kick) with preloaded FBX from `assets/weapons/`, rendered in a separate SubViewport (`own_world_3d`, `cull_mask = 2`). They only animate/recoil — all damage comes from the player's RayCast. `test/test_weapon_system.gd` asserts exactly 3 weapons with these names.
- **Pause menu:** two menus are instanced inside `player.tscn` under `PauseMenus` (CanvasLayer `layer = 2`, above effects): `PauseMenu.tscn` (red/`pause_menu.gd`) for normal mode and `PauseMenuBW.tscn` (black-white/`pause_menu_bw.gd`) for the dark B/W mode. Both use `process_mode = PROCESS_MODE_ALWAYS` and only close on `ui_cancel` when visible; `player.gd:_open_pause_menu()` opens the one matching the current mode (it pauses the tree + shows the mouse, the visible menu unpauses on Esc/Resume).
- **Glow:** `scenes/glow/glow_body.gd` (a child `Node` on a body, in the `glow_body` group) sets a white emissive `material_overlay` on the body's `MeshInstance3D`s via `set_glow(bool)`. `DarkMode.set_dark_mode()` toggles all of them. Glow is off in normal mode.
- **Scene flow:** main scene is `scenes/ui/main_menu/main_menu.tscn`; it loads `scenes/levels/test_level/test_level.tscn`.
- **Destruction is editor-baked:** active addon `voronoishatter` + `scenes/destruction/destruction.gd` (`@tool`, `class_name DestroyedController`). Its "Generate Fracture meshe" export button bakes `resource/destoy/scenes/<Name>_<seed>_destroyed.tscn` (note the **"destoy" typo** in the path — it is real). Runtime `destroy()` swaps the intact mesh for that pre-baked scene. Settings: `resource/destoy/presets/destroy_settings.gd` (`class_name DestroySettings`); `project.godot` defines a `destruction` global group.
- **UIDs:** Godot 4.4+ references scenes/scripts by `uid://` and committed `.gd.uid` files. Never hand-edit UIDs; when moving/renaming a scene or script, use the editor so UIDs and `uid://` references update — manual renames silently break references.
- **Committed vs ignored:** `.import` and `.gd.uid` files are committed. Only `.godot/` and `/android/` are gitignored.
- **Conventions:** commit messages and some code comments are in Russian — match the language of the surrounding code/comment. Scripts use tabs, snake_case, `_`-prefixed private members.

## Testing

- The only test is `test/test_weapon_system.gd` (extends SceneTree). Run it with:

  ```
  godot --path . -s res://test/test_weapon_system.gd
  ```

- It instantiates `player.tscn`, asserts all 3 weapons load/switch/fire (and that the Beretta slide returns), prints `WEAPON SYSTEM TEST PASSED` and `quit(0)`; on failure it `push_error`s and `quit(1)`. Run it after touching `player.gd`, `weapon_manager.gd`, or `player.tscn`.

## Layout

- `scenes/` — grouped by domain: `levels/`, `player/`, `ui/`, `destruction/`, `glow/` (each scene has a matching `.gd` script beside it); `scenes/rigid_body_3d.tscn` at the root is a test prop.
- `scenes/levels/test_level/dark_mode.gd` — toggles world darkness (materials/light/sky/ambient) + the `glow_body` group.
- `assets/weapons/{shotgun,pistol,legkick}/source/*.fbx` — raw weapon models, preloaded directly by `weapon_manager.gd`.
- `resource/destoy/` — destruction bake output (`scenes/`) and `DestroySettings` presets.
- `test/` — the integration test script.
- `materials/`, `materials/textures/` — materials and textures.
- `addons/` — `voronoishatter` (active plugin, drives the destruction flow) and `godot-prototype-texture` (plain checker/grid texture assets, not an active plugin).

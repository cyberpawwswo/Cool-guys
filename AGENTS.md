# AGENTS.md

Godot 4.7 3D game (GDScript), GL Compatibility renderer + Jolt physics — game-jam style, no lint/build tooling. Verify changes by loading the project in the Godot 4.7 editor or `godot --path .` (imports/parse errors show on load). One integration test exists — see Testing.

## Key facts

- **GDScript only.** `project.godot` has a `[dotnet]` section but there is no `.csproj` or C# code — do not add C#. (`addons/voronoishatter/CSVoronoiAdapter/*.cs` is vendored dead code that cannot compile without a csproj.)
- **Input actions are defined in `project.godot`, not in code:** WASD move, Space jump, Shift sprint, Ctrl dash, LMB `attack`, RMB `web_swing`, F `strong_attack` (headbutt), H `black_white` (toggles the dark B/W mode — grayscale filter + dark blink + world darkness). Exception: weapon switching (1–4, mouse wheel) and reload (R) are hardcoded `physical_keycode` checks in `weapon_manager.gd:handle_input()`, not InputMap actions. With Web Shooters selected, LMB controls the left web and RMB controls the right web. Add/rename actions in `project.godot`.
- **Two visual modes toggled by H:** normal (bright world, textures visible, no filter) and dark B/W — the **"frenzy" buff state** (commit: "сделал переход в бешенство"). It dims world materials/sky/light so textures hide, glows `glow_body` meshes white, adds a grayscale filter + dark blink, muffle-filters the master audio bus — **and buffs the player** (`bw_speed_multiplier` 1.35× speed, `bw_dash_speed`/`bw_dash_duration`, `bw_reload_speed_multiplier` 1.6× reload; headbutt gets `close_multiplier`). The player (`player.gd:_toggle_black_white_mode`) toggles filter/blink and calls `DarkMode.set_dark_mode()` on the current level (`scenes/levels/test_level/dark_mode.gd`).
- **Player & combat live in `scenes/player/player.gd`** (CharacterBody3D). LMB (`attack`) calls `weapon_manager.play_attack()` (viewmodel anim/cooldown/ammo) then `_perform_attack()`: a RayCast3D impulse on `RigidBody3D` colliders; also zeroes `body.hp` if the collider has that property. F (`strong_attack`) is **press-to-grab / release-to-throw**: on press it `_try_grab()`s a `RigidBody3D` within `close_distance` and carries it, on release the headbutt windup throws it; with nothing grabbed it's a plain timed headbutt whose strike (`_perform_attack(true, ...)`) only hits within `close_distance`.
- **Weapons are viewmodel-only for damage, but manage their own ammo/effects:** `scenes/player/weapon_manager.gd` hardcodes `WEAPON_DATA` (Boomstick / Beretta / Leg Kick / Web Shooters), rendered in a separate SubViewport (`own_world_3d`, `cull_mask = 2`). Firearms and Leg Kick use imported FBX; Web Shooters use `scenes/player/web_shooters_viewmodel.tscn`. Firearms handle magazine/reserve ammo (`uses_ammo`, `magazine_capacity`, `starting_reserve`, R reload), barrel-anchored muzzle flash/smoke/spark/gas (`muzzle_position` in `WEAPON_DATA`), fire/tail/reload sounds, and spring recoil — but all damage comes from the player's RayCast. Web swinging lives in `player.gd` and is enabled only while slot 4 is selected. `test/test_weapon_system.gd` asserts exactly 4 weapons with these names.
- **`Config` autoload (`config.gd`) holds a hardcoded API key** (`api_key`, `model_name`, `base_url`) used by the `openai_api` addon via `scenes/npc/llm_tests/ai_controller.gd` (`class_name AiController`, sends chat prompts through `OpenAI.prompt_gpt`). The key is committed; don't add new secrets.
- **Pause menu:** two menus are instanced inside `player.tscn` under `PauseMenus` (CanvasLayer `layer = 2`, above effects): `PauseMenu.tscn` (red/`pause_menu.gd`) for normal mode and `PauseMenuBW.tscn` (black-white/`pause_menu_bw.gd`) for the dark B/W mode. Both use `process_mode = PROCESS_MODE_ALWAYS` and only close on `ui_cancel` when visible; `player.gd:_open_pause_menu()` opens the one matching the current mode (it pauses the tree + shows the mouse, the visible menu unpauses on Esc/Resume).
- **Glow:** global autoload `GlowManager` (`scenes/glow/glow_manager.gd`) drives it — objects just need to be in the `glow_body` group (no script on them). `GlowManager.set_glow(bool)` walks every group node, collects `MeshInstance3D`s from the node itself or its children (recursively), and sets a white emissive `material_overlay`. `DarkMode.set_dark_mode()` calls `GlowManager.set_glow(dark)`. Glow is off in normal mode. There is no per-object glow script anymore — do not add one; just put the node in the group.
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

- It instantiates `player.tscn`, asserts all 4 weapons load/switch and the three attack weapons fire, then checks much more: ammo HUD (`ammo_label` text), per-barrel muzzle effects (flash/smoke/spark/gas anchored to `muzzle_position`), layered fire + low-fire-tail audio (polyphony ≥ 4, boosted volume), camera recoil + screen flash/concussion, spring-recoil settling, shell-by-shell Boomstick reload and Beretta full-magazine reload (incl. the slide returning), switching/empty-mag edge cases, slot 4 and mouse-wheel forwarding. Prints `WEAPON SYSTEM TEST PASSED` and `quit(0)`; on failure it `push_error`s and `quit(1)`. `test/test_web_shooter.gd` separately verifies dual attachment, independent release, LMB/RMB mapping and momentum. Run both after touching `player.gd`, `weapon_manager.gd`, or `player.tscn`.

## Layout

- `scenes/` — grouped by domain: `levels/`, `player/`, `ui/`, `npc/` (LLM test scene), `destruction/`, `glow/` (each scene has a matching `.gd` script beside it); `scenes/rigid_body_3d.tscn` at the root is a test prop.
- `scenes/levels/test_level/dark_mode.gd` — toggles world darkness (materials/light/sky/ambient) + the `glow_body` group.
- `assets/weapons/{shotgun,pistol,legkick}/source/*.fbx` — the 3 imported weapon models used by `weapon_manager.gd`; Web Shooters use the procedural `scenes/player/web_shooters_viewmodel.tscn` (other folders like `aks74`/`remington`/`uzi` are unused assets).
- `resource/destoy/` — destruction bake output (`scenes/`) and `DestroySettings` presets.
- `test/` — the integration test script.
- `materials/`, `materials/textures/` — materials and textures.
- `addons/` — `voronoishatter` and `openai_api` (both active plugins) and `godot-prototype-texture` (plain checker/grid texture assets, not an active plugin).

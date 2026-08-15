class_name DestroySettings
extends Resource

@export_group("Materials")
@export var random_color: bool = true              # Random Color (Вкл)
@export var inherit_outer_material: bool = false   # Inherit Outer Material (Выкл)
@export var use_mesh_materials: bool = false       # Использовать материалы меша (новое)
@export var outer_material: Material               # Outer Material
@export var inner_material: Material               # Inner Material

@export_group("Structure")
@export var samples: int = 32                      # Samples
@warning_ignore("shadowed_global_identifier")
@export var seed: int = 0                          # Seed
@export var cell_scale: float = 1.0                # Cell Scale
@export var sample_texture: Texture3D              # Sample Texture
@export var randomize_seed: bool = false           # бывшая кнопка "Randomize seed" — теперь галочка

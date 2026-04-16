class_name LoadingData extends Resource

@export var main_scene_path: String = "res://main/levels/mainlevel.tscn"
@export var prefabs_to_load: Array[PackedScene] = []
@export var meshes_to_store: Dictionary = {}
@export var materials_to_compile: Array[Material] = []

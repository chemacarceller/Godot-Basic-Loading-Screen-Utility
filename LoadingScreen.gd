# It is a class with a UI with loading progress bars
# This script enables the preload of prefabs with their meshes
# And also the precompilation of a series of materials of the scene to be load
extends Node3D

var _temp_compiler_meshes: Array[MeshInstance3D] = []

# Stores the scene to be loaded once the preload and precompile process has finished
## Stores the scene to be loaded once the preload and precompile process has finished
@onready var _scene_path : String = "res://main/levels/mainlevel.tscn"


# All scenes to be loaded one after the other, can be empty (scenes = prefabs)
## All scenes to be loaded one after the other, can be empty (scenes = prefabs)
@onready var _scene_paths : Array[String] = ["res://main/prefabs/weapons/assault_rifle/assault_rifle.tscn","res://main/prefabs/bullets/projectile/projectile.tscn"]
var _scene_paths_element : String = ""
# Meshes of the previous prefabs to be located in memory, the key is the name of the prefab
@onready var _meshes : Dictionary = {
	"assault_rifle" : ["res://main/prefabs/weapons/assault_rifle/mesh/assault_rifle.tres"]
}

# All materials to be compiled, can be empty
## All materials to be compiled, can be empty
@onready var _materials : Array[String] = ["res://main/levels/mainlevel/world/materials/green.tres", "res://main/levels/mainlevel/world/materials/yellow.tres","res://main/levels/mainlevel/world/materials/blue.tres","res://main/levels/mainlevel/world/materials/worldmap2.tres","res://main/levels/mainlevel/world/materials/worldmap1.tres","res://main/levels/mainlevel/world/materials/chess5.tres","res://main/levels/mainlevel/world/materials/chess4.tres","res://main/levels/mainlevel/world/materials/chess3.tres","res://main/levels/mainlevel/world/materials/chess2.tres","res://main/levels/mainlevel/world/materials/chess1.tres","res://main/levels/mainlevel/world/materials/bricks2.tres","res://main/levels/mainlevel/world/materials/bricks1.tres","res://main/prefabs/weapons/assault_rifle/materials/DarkMetal.tres","res://main/prefabs/weapons/assault_rifle/materials/DarkWood.tres","res://main/prefabs/weapons/assault_rifle/materials/Metal.tres","res://main/prefabs/weapons/assault_rifle/materials/Black.tres","res://main/characters/remi/materials/remi_skeleton3d_tops.tres","res://main/characters/remi/materials/remi_skeleton3d_shoes.tres","res://main/characters/remi/materials/remi_skeleton3d_hair.tres","res://main/characters/remi/materials/remi_skeleton3d_bottoms.tres","res://main/characters/remi/materials/remi_skeleton3d_body.tres","res://main/characters/man/materials/man_skeleton_body.tres","res://main/characters/man/materials/man_skeleton_hair.tres","res://main/characters/brian/materials/brian.tres"]

# Indicates which scene and which material of the previous arrays is being loaded
var _scene_index : int = 0
var _material_index : int = 0

# Array so that the materials are not compiled twice
var _foundMaterials: Array[Material] = []


# Indicates if the scenes preloading process is runing, used to say when all the scenes are preload
# Used to load the scene to be shown previously the materials are precompiled
var _scenesBeingLoaded : bool = false


@export_range(5.0,250.0) var progress_speed : float = 100.0


# Signel emitted when a scene is loaded and there are other scenes to be loaded or materials to be compiled
signal screenLoaded


# variable to access the progress bars and the text
@onready var progress_bar1 : ProgressBar = $HUD/ProgressBar1
@onready var progress_bar2 : ProgressBar = $HUD/ProgressBar2
@onready var label2 : Label = $HUD/Label2
@onready var godot_image : TextureRect = $HUD/GodotImage

# Actual progress value; we move towards this value
var _progress1_value : float = 0.0
var _progress2_value : float = 0.0

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		MyLogger.info(" LoadingScreen Exiting : " + name + " ..." , 'LoadingScreen.gd',61,true)


# Load the scene at the given path.
# When this is finished loading, the "scene_loaded" signal will be emitted.
func _ready() -> void:  

	# Progress Bar 2 should be used ?
	# If the scenes array has only one member and there ara none material to be compiled the second progressbar has no sense, hiding it and putting to 100%
	# If the scenes array is empty but there are materials to compile the second progressbar has no sense, hiding it and putting to 100%
	if (_scene_paths.size() <= 1 and _materials.size() == 0) or (_scene_paths.size() == 0 and _materials.size() > 0):
		progress_bar2.value=100
		_progress2_value = 100
		progress_bar2.hide()
	else :
		progress_bar2.value=0.0
		_progress2_value = 0.0
		progress_bar2.show()

	# Connecting the signal to a function
	screenLoaded.connect(_launch_loading)

	# Initializing the progress bar 1 value
	progress_bar1.value=0.0

	# If there are no scenes go to the next step saying that the scenes loading process has begun
	if _scene_paths.size() == 0 :
		_scenesBeingLoaded = true
		screenLoaded.emit()
	else : 
		# Loading the first scene
		_scene_index = 0
		label2.text = "Loading Prefabs... " + _scene_paths[_scene_index].get_file().get_basename()

		# Begin the scenes preloading process
		_scenesBeingLoaded = true
		_load_scene(_scene_paths[_scene_index])


func _load_scene(path : String) :
	# Begins the loading process...
	# Doing the two options synchronous and asynchronous
	MyLogger.info("The prefab : " + path + " is being LOADED",'loadingscreen.gd',126,true)
	_scene_paths_element = path
	ResourceLoader.load_threaded_request(path, "", true)

	# Loading the meshes of the prefab being loaded
	if _meshes.has(path.get_file().get_basename()) :
		for mesh in _meshes[path.get_file().get_basename()] :
			MyLogger.info("The mesh : " + mesh + " is being LOADED",'loadingscreen.gd',129,true)
			GameInstance._meshes.append(load(mesh))
			MyLogger.info("The mesh : " + str(load(mesh)) + " has been stored in memory",'loadingscreen.gd',130,true)


func _load_material(path : String) :

	# if is already cached go to the next scene emitting the signal that executes the _launch_loading() function
	# Not used, force to load again the material if needed due to the progress bar behaviour we want to have loading one after the other when the bar2 arrives its right value
	# Uncomment it if you prefer not loading the materials again
	#if ResourceLoader.has_cached(path) :

		# The compilation is being done via the _precompile_material function
		#var mat : Material = ResourceLoader.load(_materials[_material_index]) as Material
		#_precompile_material(mat)

		#_material_index += 1
		#screenLoaded.emit()
	#else :
		# Begins the loading process...
		ResourceLoader.load_threaded_request(path, "", true)
		MyLogger.info("The material : " + path + " is being LOADED,","loadingscreen.gd", 147)





# Function to process the signal emitted
# Just load the next scene or the next material or just load the last scene
func _launch_loading() :

	# If there are more scenes to be loaded...
	# If the index is equal the array size that means we are out of bounds and must change to material loading
	if _scene_index < _scene_paths.size() :

		# Reseting the progress bar
		_progress1_value = 0.0
		progress_bar1.value=0.0

		# Loading the next scene in memory
		label2.text = "Loading Prefabs... " + _scene_paths[_scene_index].get_file().get_basename()
		_load_scene(_scene_paths[_scene_index])

	else :
		# The _scenesBeingLoaded is put to false indicating the scene process has finished 
		# Also used to execute some code only once, that is preparing the level to be loaded and reseting the progress bar 1
		if _scenesBeingLoaded :
			_scenesBeingLoaded = false

			_progress1_value = 0.0
			progress_bar1.value=0.0

		# If the materials array is empty just loading the main scene
		if _materials.size() == 0 :
			_prepare_for_exit() # Clean up before leaving!
			LevelManager.load_new_level(_scene_path)

		# If it is request a valid material
		if _material_index < _materials.size() :
			# We load all the materials one after the other and precompile them
			_load_material(_materials[_material_index])

		# If we had scenes to load the new level is loaded when progress 2 bar arrives to 100
		# If we dont have scenes to load the new level is loaded when progress 1 bar arrives to 100
		if (_scene_paths.size() > 0 and progress_bar2.value >= 99.0) or (_scene_paths.size() == 0 and progress_bar1.value >= 99.0) :
			_prepare_for_exit() # Clean up before leaving!
			LevelManager.load_new_level(_scene_path)


# Executed each frame, main function that handles the loading and compiling process
func _process(delta: float):

	# If the loading process of the scenes has began and not ended or there are materials to compiled
	if _scenesBeingLoaded or _materials.size() > 0:

		# Modifying the progress bar
		var progress : Array = []
		var status : ResourceLoader.ThreadLoadStatus
		
		# We distingue between scene loading or materials compiling
		if _scenesBeingLoaded :

			# We are loading scenes...
			status = ResourceLoader.load_threaded_get_status(_scene_paths[_scene_index], progress)

			# Scene loading in process
			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS :
				_progress1_value = progress[0] * 100
				progress_bar1.value = move_toward(progress_bar1.value, _progress1_value, delta * progress_speed)

			# Scene loading finished
			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED :
				# put the progress bar to 100% so we don't get weird visuals and update the seconf bar progress
				progress_bar1.value = move_toward(progress_bar1.value, 100.0, delta * progress_speed * _scene_paths.size())
				
				# Once the process has finished in the sense that the bar 1 arrives 100% the progress bar 2 moves to the corresponding value
				if progress_bar1.value == 100 :
					
					# If there are no materials the bar 2 goes to 100%
					# If there are materials the bar 2 goes to 50%
					if _materials.size() == 0 :
						_progress2_value = (float) (_scene_index + 1) * 100 / _scene_paths.size()
					else :
						_progress2_value = (float) (_scene_index + 1) * 50 / _scene_paths.size()

					# Only when the second bar arrives the corresponding value it goes to the next step
					if round(progress_bar2.value) == round(_progress2_value) :
						_scene_index += 1
						
						# One prefab is already loaded, we make a reference in memory, used by spawning
						var prefabObj : PackedScene = ResourceLoader.load_threaded_get(_scene_paths_element) as PackedScene
						GameInstance._prefabs[_scene_paths_element.get_file().get_basename()]= prefabObj
						MyLogger.info("The prefab " + _scene_paths_element.get_file().get_basename() + " -- " + str(prefabObj) + " has been stored in memory in GameInstance._prefabs['" + _scene_paths_element.get_file().get_basename()  + "'] to be spawned in an ultra-fast way",'loadingscreen.gd',237,true)
						screenLoaded.emit()

				progress_bar2.value = move_toward(progress_bar2.value, _progress2_value, delta * progress_speed)
	
		else :

			# Shaders compiling...
			# Progress Bar 1 is used to show the process of material compilation
			_progress1_value = _material_index as float * 100 / _materials.size() as float
			
			# The second bar only used if previous scenes where preloaded, in this case t goes from 50% to 100%
			# If no scenes are being preloaded the second bar is not shown, just simply is set yo 100% but not used
			if (_scene_paths.size() > 0) : _progress2_value = 50.0 + (_progress1_value / 2)
			else : _progress2_value = 100

			# The progress bar 1 in action...
			progress_bar1.value = move_toward(progress_bar1.value, _progress1_value, delta * progress_speed)

			# The progress bar 2 only in action if there were scenes preloaded
			if (_scene_paths.size() > 0) :
				progress_bar2.value = move_toward(progress_bar2.value, _progress2_value, delta * progress_speed)

			# Order to precompile the material once is loaded and the progress_bar arrives its corresponding value
			if _material_index < _materials.size() :

				# If we have a valid material
				status = ResourceLoader.load_threaded_get_status(_materials[_material_index], progress)

				# if is loaded and the progress bar has arrived the target controlled via the progress bar 1, it is used the round function to avoid difference in decimals
				if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED and round(progress_bar1.value) == round(_progress1_value) :
					
					# The compilation is being done via the _precompile_material function
					var mat : Material = ResourceLoader.load_threaded_get(_materials[_material_index]) as Material
					_precompile_material(mat)

					# Once compiled the material we continue with the next one
					_material_index += 1
					screenLoaded.emit()

			# If we dont have any more material and the progress bar has arrived to 100%
			# This is needed because we wait until bar2 arrives 100% once all materials are loaded
			elif progress_bar1.value == 100 :
				screenLoaded.emit()
				
	# If we have none material and the scene preload process has finished
	# No needed because never arrives here due to in this case previously the scene is changed
	else :
		screenLoaded.emit()





# Utility functions for precompiling the materials

func _precompile_material(mat : Material) -> void :
	if mat == null:
		MyLogger.error("Failed to compile: Material is null", "loadingscreen.gd")
		return # Skip this iteration

	if not mat in _foundMaterials:
		_add_material(mat)
		_foundMaterials.append(mat)
		GameInstance._materials.append(mat)


func _add_material(mat: Material) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ZERO # Keep it invisible
	
	var newMesh: MeshInstance3D = MeshInstance3D.new()
	newMesh.mesh = quad
	
	# CRITICAL: Disable shadows to avoid the GLES3 null material check
	newMesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Assign the material
	newMesh.set_surface_override_material(0, mat)
	
	# Add to the current tree (the loading screen itself is safest)
	add_child(newMesh)
	
	# Force a transform update to nudge the renderer to compile the shader
	newMesh.position = Vector3(randf(), randf(), randf())
	
	# Optional: Keep the label updated
	label2.text = "Compiling... " + mat.resource_path.get_file().get_basename()

	# Store the reference so we can delete it later
	_temp_compiler_meshes.append(newMesh)


func _prepare_for_exit():
	# 1. Remove and free the dummy meshes used for compilation
	for mesh in _temp_compiler_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_temp_compiler_meshes.clear()

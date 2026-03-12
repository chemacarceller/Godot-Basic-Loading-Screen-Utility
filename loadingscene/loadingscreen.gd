# It is a class with a UI with loading progress bars
# This script enables the preload of typically one scene but possibility of more scenes
# and also the precompilation of a series of materials of the scene to be load, the materials are loaded in this scene and also in the scene to be load
# The way it works is :
# On the ready function the first scene is loaded, the process function handles the process bar and when the scene is loaded and the bars are right positioned a signal is emitted after the scene_index is incremented
# the signal is captured in the _launch_loading function that detects if there are more scenes to load or not
# if there are still scenes the next scene is loaded and the process repeats
# if not it is checked if thera are minimum one material, if the scene is shown
# if there are materials, the previous process is done for the materials array items
# When there are no more materials and the bar2 arrives 100% the last scene is shown
# It is also possible there are no scene to preload and only materials to precompile
class_name LoadingScreen extends Node3D


# Stores the scene to be loaded once the preload and precompile process has finished
## Stores the scene to be loaded once the preload and precompile process has finished
@export var _scene_path : String = ""


# Stores the PackedScene to be loaded at the end of the process
var _loading_scene : PackedScene = null
# Node of the previous packedScene
var _loading_scene_node : Node = null





# Indicates if the scenes preloading process is runing, used to say when all the scenes are preload
# Used to load the scene to be shown previously the materials are precompiled
var _scenesBeingLoaded : bool = false




# All scenes to be loaded one after the other, can be empty
## All scenes to be loaded one after the other, can be empty
@export var _scene_paths : Array[String] = []

# All materials to be compiled, can be empty
## All materials to be compiled, can be empty
@export var  _materials : Array[String] = []





# Array so that the materials are not compiled twice
var _foundMaterials: Array[Material] = []





# Indicates which scene and which material of the previous arrays is being loaded
var _scene_index : int = 0
var _material_index : int = 0



@export_range(5.0,250.0) var progress_speed : float = 100.0




# Signel emitted when a scene is loaded and there are other scenes to be loaded or materials to be compiled
signal screenLoaded



# Actual progress value; we move towards this value
var _progress1_value : float = 0.0
var _progress2_value : float = 0.0



# variable to access the progress bar
@onready var progress_bar1 : ProgressBar = $HUD/ProgressBar1
@onready var progress_bar2 : ProgressBar = $HUD/ProgressBar2
@onready var label2 : Label = $HUD/Label2




func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if progress_bar1 != null : progress_bar1.queue_free()
		if progress_bar2 != null : progress_bar2.queue_free()
		if label2 != null : label2.queue_free()
		_loading_scene = null
		queue_free()




# Load the scene at the given path.
# When this is finished loading, the "scene_loaded" signal will be emitted.
func _ready() -> void:  

	# If in GameInstance are these parameters defined...
	if GameInstance._scene_path != "" :
		_scene_path = GameInstance._scene_path

	if GameInstance._scene_paths != null :
		_scene_paths = GameInstance._scene_paths

	if GameInstance._materials != null :
		_materials = GameInstance._materials


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
		label2.text = _scene_paths[_scene_index].split("/")[_scene_paths[_scene_index].split("/").size() - 1].split(".")[0]

		# Begin the scenes preloading process
		_scenesBeingLoaded = true
		_load_scene(_scene_paths[_scene_index])


func _load_scene(path : String) :
	# if is already cached go to the next scene emitting the signal that executes the _launch_loading() function
	if ResourceLoader.has_cached(path) :
		_scene_index += 1
		screenLoaded.emit()
	else :
		# Begins the loading process...
		# Doing the two options synchronous and asynchronous
		ResourceLoader.load_threaded_request(path, "", true)

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
		label2.text = _scene_paths[_scene_index].split("/")[_scene_paths[_scene_index].split("/").size() - 1].split(".")[0]
		_load_scene(_scene_paths[_scene_index])

	else :
		# The _scenesBeingLoaded is put to false indicating the scene process has finished 
		# Also used to execute some code only once, that is preparing the level to be loaded and reseting the progress bar 1
		if _scenesBeingLoaded :
			_scenesBeingLoaded = false
			if ResourceLoader.has_cached(_scene_path) :
				_loading_scene = ResourceLoader.load_threaded_get(_scene_path) as PackedScene
			else :
				_loading_scene = ResourceLoader.load(_scene_path) as PackedScene
			_loading_scene_node = _loading_scene.instantiate()

			_progress1_value = 0.0
			progress_bar1.value=0.0
			label2.text = "Loading Shaders... "

		# If the materials array is empty
		if _materials.size() == 0 :
			_change_scene_to_node(_loading_scene_node)

		# If it is request a valid material
		if _material_index < _materials.size() :
			# We load all the materials one after the other and precompile them
			_load_material(_materials[_material_index])

		# If we had scenes to load the new level is loaded when progress 2 bar arrives to 100
		# If we dont have scenes to load the new level is loaded when progress 1 bar arrives to 100
		if (_scene_paths.size() > 0 and progress_bar2.value == 100) or (_scene_paths.size() == 0 and progress_bar1.value ==100) :
			_change_scene_to_node(_loading_scene_node)


func _change_scene_to_node(node : Node) -> void :
	# This is the process to change scene instead ot using the change_scene methods
	# due to the fact that we have create the level for the materials copilation
	# We get the reference to the actual scene and free them
	var root_node = get_tree().get_root()
	var scene_node = root_node.get_node("LoadingScreen")
	scene_node.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().get_root().remove_child(scene_node)
	scene_node.queue_free()
	
	# We add the node of the level to the root node
	if node.get_parent() == null :
		root_node.add_child.call_deferred(node)
	elif not node.get_parent() == get_tree().get_root() :
		node.reparent(root_node)
	


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
	# The compilation process just calling the _add_material function and manage the _foundmaterials array
	if not mat in _foundMaterials:
		_add_material(mat)
		_foundMaterials.append(mat)


func _add_material(mat: Material) -> void:
	# This is the real method to compile the material

	# We create a QuadMesh and a Meshinstance3D
	var quad: QuadMesh = QuadMesh.new()
	var newMesh1: MeshInstance3D = MeshInstance3D.new()
	var newMesh2: MeshInstance3D = MeshInstance3D.new()
	
	#Assign mesh to the mesh instance 3d
	newMesh1.mesh = quad
	newMesh2.mesh = quad

	# position out of the scene view but i think it must be inside the camera frustum. may be that is not necessary because the size of the QuadMesh is set to zero
	newMesh1.position = Vector3.ZERO
	newMesh2.position = Vector3.ZERO

	# Testing ...
	# scale the mesh instance 3d to zero and hide it - if the scale is zero it doesnt work if it is hidden it doesnt work
	#newMesh.scale = Vector3.ZERO
	#newMesh.hide()
	
	# scale the mesh to ZERO, that works fine
	quad.size = Vector2.ZERO
	
	# Assigned material. I guess both options are similar
	quad.surface_set_material(0,mat)
	newMesh1.set_surface_override_material(0,mat)
	newMesh2.set_surface_override_material(0,mat)

	# Adding to the scene to be loaded and set its owner
	# Better in the loadingscreen over the mainlevel scene
	
	_loading_scene_node.add_child(newMesh1)
	add_child(newMesh2)
	
	newMesh1.set_owner(_loading_scene_node)
	newMesh2.set_owner(self)

	# Change the translation and rotation briefly, no idea why, just copied from the script
	# https://github.com/Brandt-J/ShaderPrecompiler  MIT License
	# I guess it is necessary so that godot compiles the material
	newMesh1.position.x += randf() - 0.5
	newMesh1.position.y += randf()/2 - 0.25
	newMesh1.position.z += randf() - 0.5
	newMesh2.position.x += randf() - 0.5
	newMesh2.position.y += randf()/2 - 0.25
	newMesh2.position.z += randf() - 0.5

	newMesh1.rotate_x(randf() * 0.2)
	newMesh1.rotate_y(randf() * -0.3)
	newMesh1.rotate_z(randf() * 0.1)
	newMesh2.rotate_x(randf() * 0.2)
	newMesh2.rotate_y(randf() * -0.3)
	newMesh2.rotate_z(randf() * 0.1)
	
	# If we remove the mesh instance 3d it doesnt work
	#loading_scene_node.remove_child(newMesh)
	#newMesh.queue_free()
	# With it doesnt work i mean the material is nor precompiled, not that an error appears
	
	var items = mat.resource_path.split("/")
	label2.text = "Loading Shaders...  " + items[items.size() - 1 ].split(".")[0]
	print("Material : " + items[items.size() - 1 ] + " LOADED")

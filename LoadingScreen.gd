# It is a class with a UI with loading progress bars
# This script enables the preload of prefabs with their meshes
# And also the precompilation of a series of materials of the scene to be load
# This class optionally uses a Global object called MyLogger, which must provide the methods info(), warn(), and error() to manage log storage; otherwise, the logs are displayed directly in the console.
# In the case of having a Global instance called GameInstance that implements the GameInstance._quit_gracefully() method for controlled application closure, it would be used instead of an uncontrolled closure

# It will be mandatory to have a GameInstance as Global and that it contains the following defined:
# GameInstance variables that store materials, meshes and the prefabs
# var _materials: Array[Material] = []
# var _meshes : Array[Mesh] = []
# var _prefabs : Dictionary = {}
# Since the purpose of this loading screen will be to load scenes, meshes, and materials and maintain them globally in the game

extends Node3D

# Configures the speed at which the progress bar animation will play
## Configures the speed at which the progress bar animation will play for scenes (prefabs)
@export_range(0.01,5.0) var progress_time_scenes : float = 2.0
## Configures the speed at which the progress bar animation will play for materials
@export_range(0.01,5.0) var progress_time_materials : float = 0.25

# Variable to assign the .tres files from the Inspector
## Variable to assign the .tres files from the Inspector
@export var data_resource: LoadingData


# Variables whose content is obtained from the data_resource variable in _ready

# Stores the scene to be loaded once the preload and precompile process has finished
var _scene_path : String

# All scenes to be loaded one after the other, can be empty (scenes = prefabs)
var _scene_paths_element : String = ""
var _scene_paths : Array[String] = []

# All materials to be compiled, can be empty
var _materials : Array[Material] = []

# Store the meshes that need to be compiled
var _meshes_to_store : Dictionary = {}

# =============================================================================



# Auxiliary variable containing the meshes temporarily stored for material compilation
var _temp_compiler_meshes_to_store: Array[MeshInstance3D] = []

# Indicates which scene and which material of the previous arrays is being loaded
var _scene_index : int = 0
var _material_index : int = 0

# Indicates if the scenes preloading process is runing, used to say when all the scenes are preload
# Used to load the scene to be shown previously the materials are precompiled
var _scenesBeingLoaded : bool = false


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
	if what == NOTIFICATION_WM_CLOSE_REQUEST :
		if get_node_or_null("/root/MyLogger") != null : MyLogger.info(" LoadingScreen Exiting : " + name + " ..." , 'LoadingScreen.gd',75,true)
		else : print("[INFO]", " LoadingScreen Exiting : " + name + " ...", 'LoadingScreen.gd(75)')


func _ready() -> void:

	# List of required singletons
	var required_globals = ["GameInstance", "LevelManager"]
	var missing_globals = []

	for global_name in required_globals:
		if not is_instance_valid(get_node_or_null("/root/" + global_name)):
			missing_globals.append(global_name)

	# If anyone is missing, we abort the mission
	if missing_globals.size() > 0 :

		var error_msg = "CRITICAL ERROR: Missing Autoloads : " + str(missing_globals)
		
		if get_node_or_null("/root/MyLogger") != null : MyLogger.error(error_msg, 'LoadingScreen.gd', 83, true)
		else : printerr("[ERROR] ", error_msg)
		
		# Opcional: Mostrar el error en la UI para que el tester sepa qué pasa
		label2.text = "System Error: Singletons are missing"

		# Desactivamos el bucle principal
		set_process(false) 

		# If we are in debug mode, we might want to see the error.
		# If it's the final game, it's better to close it than to leave the screen frozen.
		if OS.is_debug_build() : label2.text = "Configuration Error: Check the Console"
		else : get_tree().quit()
		return

	# We extract the data from the exported data resource variable
	if data_resource :

		_scene_path = data_resource.main_scene_path
		
		# We convert the PackedScenes to String routes for the ResourceLoader
		for scene in data_resource.prefabs_to_load:
			_scene_paths.append(scene.resource_path)
			
		_materials = data_resource.materials_to_compile

		_meshes_to_store = data_resource.meshes_to_store
		
		# The loading Screen is loaded form the Project settings
		if get_node_or_null("/root/MyLogger") != null : MyLogger.info(name + " Instantiated ... ","LoadingScreen.gd",95, true)
		else : print("[INFO]",name + " Instantiated ... ",'LoadingScreen.gd(96)')

		# Setting the loading screen camera
		var camera = get_node("Camera3D")
		if camera : camera.make_current()

		# Progress Bar 2 should be used ?
		# If the scenes array has only one member and there ara none material to be compiled the second progressbar has no sense, hiding it and putting to 100%
		# If the scenes array is empty but there are materials to compile the second progressbar has no sense, hiding it and putting to 100%
		if (_scene_paths.size() <= 1 and _materials.size() == 0) or (_scene_paths.size() == 0 and _materials.size() > 0):
			progress_bar2.value=100.0
			_progress2_value = 100.0
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

			# Begin the scenes prefabs preloading process
			_scenesBeingLoaded = true
			_load_scene(_scene_paths[_scene_index])

	else :
		# The data resource object has not been defined
		if get_node_or_null("/root/MyLogger") != null : MyLogger.error("The necessary resources have not been defined on the loading screen",'LoadindScreen.gd',135, true)
		else : printerr("[ERROR]","The necessary resources have not been defined on the loading screen", 'LoadindScreen.gd (136)')
		
		# We exit the application if this error occurs
		if GameInstance._quit_gracefully : GameInstance._quit_gracefully()
		else : get_tree().quit()


# Function to process the signal emitted
# Just load the next scene or the next material or just load the starting scene
# This function acts as a director throughout the entire compilation process
var _is_loading_level : bool = false
func _launch_loading() :

	# If we're already leaving loading the starting scene, we ignore any residual signals.
	if _is_loading_level : return

	# If there are more scenes prefabs to be loaded...
	# If the index is equal the array size that means we are out of bounds and must change to material loading
	if _scene_index < _scene_paths.size() :
		
		_last_reported_progress1 = -1.0

		# Reseting the progress bar one
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
			if (_materials.size() != 0) :
				# Reseting the progress bar one
				_progress1_value = 0.0
				progress_bar1.value=0.0

		# If the materials array is empty just loading the main scene
		if _materials.size() == 0 :
			if not _is_loading_level : 
				# We want to leave loading the starting scene, we indicate that eith the _is_loading_level flag
				_is_loading_level = true

				label2.text = "Finalizing shaders..."
				await _finalize_and_exit()


		# If it is request a valid material
		if _material_index < _materials.size() :
			
			# We load all the materials one after the other and precompile them
			_load_material(_materials[_material_index].resource_path)

		# If we had scenes to load the new level is loaded when progress 2 bar arrives to 100
		# If we dont have scenes to load the new level is loaded when progress 1 bar arrives to 100
		if (_scene_paths.size() > 0 and is_zero_approx(progress_bar2.value - 100.0)) or (_scene_paths.size() == 0 and is_zero_approx(progress_bar1.value - 100.0)) :
			if not _is_loading_level : 
				# We want to leave loading the starting scene, we indicate that eith the _is_loading_level flag
				_is_loading_level = true

				label2.text = "Finalizing shaders..."
				await _finalize_and_exit()


# This function is used to load a prefab scene as argument receives the prefab path
func _load_scene(path : String) :

	if get_node_or_null("/root/MyLogger") != null : MyLogger.info("The prefab : " + path + " is being LOADED",'LoadingScreen.gd',206,true)
	else : print("[INFO]","The prefab : " + path + " is being LOADED", 'LoadindScreen.gd (207)')

	# Doing the request to load the prefab
	# The prefab loading is asynchronous and is managed from _process
	_scene_paths_element = path
	ResourceLoader.load_threaded_request(path, "", true)

	# Loading the meshes of the prefab being loaded
	# This is not necessary, But if we want to do a double load of meshes, we can specify
	# In some particular cases it might make some sense, for example in a prefab we want to change the mesh at runtime
	# That is, if you need to dynamically exchange it for code
	if _meshes_to_store.has(path.get_file().get_basename()) :

		# Although meshes can be specified by string, it makes sense to pass the mesh directly so the process can be synchronous
		for mesh_data in _meshes_to_store[path.get_file().get_basename()] :

			if get_node_or_null("/root/MyLogger") != null : MyLogger.info("The mesh : " + str(mesh_data) + " is being LOADED",'LoadingScreen.gd',140,true)
			else : print("[INFO]","The mesh : " + str(mesh_data) + " is being LOADED", 'LoadindScreen.gd (140)')

			var mesh_resource: Mesh
		
			# If you saved the path as a String in the Dictionary
			if mesh_data is String : mesh_resource = load(mesh_data)

			# If you dragged the file directly into the Dictionary (it's a Mesh object)
			elif mesh_data is Mesh : mesh_resource = mesh_data
			
			if mesh_resource :

				if get_node_or_null("/root/MyLogger") != null : MyLogger.info("The mesh : " + str(mesh_resource) + " has been stored in memory",'LoadingScreen.gd',233,true)
				else : print("[INFO]","The mesh : " + str(mesh_resource) + " has been stored in memory", 'LoadindScreen.gd (234)')
				
				# We added the meshes to GameInstance
				if GameInstance._meshes is Array : GameInstance._meshes.append(mesh_resource)

			else:

				if get_node_or_null("/root/MyLogger") != null : MyLogger.error("Mesh loading failed : " + str(mesh_data), "LoadingScreen.gd", 241, true)
				else : printerr("[ERROR]","Mesh loading failed : " + str(mesh_data), 'LoadindScreen.gd (242)')

# Función para cargar un material
func _load_material(path : String) :

	# An asynchronous request is made to load the material, as in prefabs, and is managed by _process
	ResourceLoader.load_threaded_request(path, "", true)
	
	if get_node_or_null("/root/MyLogger") != null : MyLogger.info("The material : " + path + " is being LOADED","LoadingScreen.gd", 253)
	else : print("[INFO]","The material : " + path + " is being LOADED", 'LoadindScreen.gd (254)')



var tween1_in_action = false
var tween2_in_action = false
var _active_tween1: Tween
var _last_reported_progress1 : float = -1.0

# Executed each frame, main function that handles the loading and compiling process both prefabs and materials
func _process(_delta: float):

	# If the output process started, we stopped processing barcode logic.
	if _is_loading_level : return

	# If the loading process of the scenes has began and not ended or there are materials to compiled
	if _scenesBeingLoaded or _materials.size() > 0:

		# Modifying the progress bar
		var progress : Array = []
		var status : ResourceLoader.ThreadLoadStatus
		
		# We distingue between scene loading or materials compiling
		if _scenesBeingLoaded :

			# We are loading scenes...
			status = ResourceLoader.load_threaded_get_status(_scene_paths[_scene_index], progress)

			var current_progress : float = progress[0] * 100.0
			if abs(current_progress - _last_reported_progress1) > 0.1:
				_last_reported_progress1 = current_progress
				_progress1_value = current_progress

			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED :
				if get_node_or_null("/root/MyLogger") != null : MyLogger.error("Error al cargar el prefab : " + str(_scene_paths[_scene_index]), 'LoadingScreen.gd', 296, true)
				else : printerr("[ERROR]", "Error al cargar el prefab : " + str(_scene_paths[_scene_index]),'LoadingScreen.gd (297)' )
					
			# Put the progress bar to 100% 
			# progress_time_scenes is the time the progress bar animation needs for each prefab (configurable)
			if not tween1_in_action :
				tween1_in_action = true
				
				# Perhaps there wasn't enough time to reset progress_bar1 in "launch_loading", we'll do it here
				if progress_bar1.value >= 99.0: progress_bar1.value = 0

				if _active_tween1: _active_tween1.kill()
				var tween = create_tween()

				# We set it to 101 so that it can never be zero and the bar remains locked
				tween.tween_property(progress_bar1, "value", 100.0, ((101.0 - progress_bar1.value)/100.0) * progress_time_scenes).set_trans(Tween.TRANS_LINEAR)

			# Progress bar two management
			# If there are no materials the bar 2 goes to 100% depending of _scene_index
			# If there are materials the bar 2 goes to 50% depending of _scene_index
			if _materials.size() == 0 :
				_progress2_value = (float) (_scene_index + 1) * 100.0 / _scene_paths.size()
			else :
				_progress2_value = (float) (_scene_index + 1) * 50.0 / _scene_paths.size()

			# The progress bar speed is ajusted so that both progress bar run synchronized
			if not tween2_in_action :
				tween2_in_action = true
				var tween2 = create_tween()
				tween2.tween_property(progress_bar2, "value", _progress2_value, progress_time_scenes).set_trans(Tween.TRANS_LINEAR)


			# Only when the second bar arrives the corresponding value it goes to the next step
			# Offset of a 1% for progress bar 2
			if abs(progress_bar2.value - _progress2_value) < 0.1 and abs(progress_bar1.value - 100.0) < 0.1 :

				_scene_index += 1

				# We store in GameInstance the instantiated object of each of the memory-intensive prefabs
				if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED :
					var prefabObj = ResourceLoader.load_threaded_get(_scene_paths_element)
					if prefabObj is PackedScene :
						var key = _scene_paths_element.get_file().get_basename()
							
						if GameInstance._prefabs is Dictionary : GameInstance._prefabs[key] = prefabObj.instantiate()
							
						if get_node_or_null("/root/MyLogger") != null : MyLogger.info("Prefab stored: " + key, 'LoadingScreen.gd', 335, true)
						else : print("[INFO]","Prefab stored: " + key, 'LoadindScreen.gd (336)')
					else:
						if get_node_or_null("/root/MyLogger") != null : MyLogger.error("Resource is not a PackedScene: " + _scene_paths_element, 'LoadingScreen', 338, true)
						else : printerr("[ERROR]","Resource is not a PackedScene: " + _scene_paths_element, 'LoadindScreen.gd (338)')

				# Preparing the next progress bar simulation
				tween1_in_action = false
				tween2_in_action = false

				# Sending the signal to the next prefab or to begin material compilation
				screenLoaded.emit()

		else :

			# Shaders compiling...
			# The Progress Bar 1 involves all the materials compilation
			# Progress Bar 1 is used to show the process of material compilation
			_progress1_value = (_material_index as float + 1.0) * 100.0 / _materials.size() as float
			if _progress1_value > 100.0 : _progress1_value = 100.0
			
			# The second bar only used if previous scenes where preloaded, in this case t goes from 50% to 100%
			# If no scenes are being preloaded the second bar is not shown, just simply is set yo 100% but not used
			if (_scene_paths.size() > 0) : _progress2_value = 50.0 + (_progress1_value / 2)
			else : _progress2_value = 100.0

			# The progress bar 1 in action...
			if not tween1_in_action :
				tween1_in_action = true
				var tween = create_tween()
				tween.tween_property(progress_bar1, "value", _progress1_value, progress_time_materials).set_trans(Tween.TRANS_LINEAR)

			# The progress bar 2 only in action if there were scenes preloaded
			if (_scene_paths.size() > 0) :
				if not tween2_in_action :
					tween2_in_action = true
					var tween = create_tween()
					tween.tween_property(progress_bar2, "value", _progress2_value, progress_time_materials).set_trans(Tween.TRANS_LINEAR)

			# Order to precompile the material once is loaded and the progress_bar arrives its corresponding value
			if _material_index < _materials.size() :

				# If we have a valid material
				status = ResourceLoader.load_threaded_get_status(_materials[_material_index].resource_path, progress)

				# if is loaded and the progress bar has arrived the target controlled via the progress bar 1, it is used the round function to avoid difference in decimals
				if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED : 
					if abs(progress_bar1.value - _progress1_value) < 0.1 : 

						# The compilation is being done via the _precompile_material function
						var mat : Material = ResourceLoader.load_threaded_get(_materials[_material_index].resource_path) as Material
						_precompile_material(mat)

						# Once compiled the material we continue with the next one
						_material_index += 1

						# Preparing the next progress bar simulation
						tween1_in_action = false
						tween2_in_action = false

						# Sending the signal to the next prefab or to begin material compilation
						screenLoaded.emit()

			# If we dont have any more material and the progress bar has arrived to 100%
			# This is needed because we wait until bar2 arrives 100% once all materials are loaded
			elif abs(progress_bar1.value - 100.0) < 0.1 :
				screenLoaded.emit()
				
	# If we have none material and the scene preload process has finished
	# No needed because never arrives here due to in this case previously the scene is changed
	else :
		screenLoaded.emit()




# Utility functions for precompiling the materials

# Function that performs double compilation just before transitioning to the main scene
func pre_compile_materials(materials_list: Array[Material]) :

	var scenario = get_world_3d().scenario
	var camera = get_viewport().get_camera_3d()
	var rids_to_free = []
	
   	# 1. Create a generic mesh
	var mesh_rid = RenderingServer.mesh_create()
	var mesh_data = SphereMesh.new()
	RenderingServer.mesh_set_custom_aabb(mesh_rid, AABB(Vector3(-1,-1,-1), Vector3(2,2,2)))
	
	for mat in materials_list:
		var inst = RenderingServer.instance_create()
		RenderingServer.instance_set_base(inst, mesh_data.get_rid())
		RenderingServer.instance_geometry_set_material_override(inst, mat.get_rid())
		RenderingServer.instance_set_scenario(inst, scenario)
		
		# Position yourself facing the camera if one exists
		if camera:
			var t = Transform3D(Basis(), camera.global_transform.origin - camera.global_transform.basis.z * 2.0)
			RenderingServer.instance_set_transform(inst, t)
		
		rids_to_free.append(inst)
	
	# 2. Wait for the engine to render the frame
	await get_tree().process_frame
	
	# 3. Clean everything
	for rid in rids_to_free:
		RenderingServer.free_rid(rid)
	RenderingServer.free_rid(mesh_rid)

	if get_node_or_null("/root/MyLogger") != null : MyLogger.info("Shader compilation complete.", "LoadingScreen.gd", 445, true)
	print("[INFO]","Shader compilation complete.","LoadingScreen.gd (446)")



# Precompilar un material en la primera compilación
func _precompile_material(mat : Material) -> void :
	if mat == null:
		if get_node_or_null("/root/MyLogger") != null : MyLogger.error("Failed to compile: Material is null", "LoadingScreen.gd", 368, true)
		else : printerr("[ERROR]","Failed to compile: Material is null", 'LoadindScreen.gd (368)')
		return 

	# Se almacena el material en GameInstance
	if GameInstance._materials is Array :
		if not mat in GameInstance._materials:
			_add_material(mat)
			GameInstance._materials.append(mat)


func _add_material(mat: Material) -> void:

	var quad: QuadMesh = QuadMesh.new()
	var newMesh: MeshInstance3D = MeshInstance3D.new()
	newMesh.mesh = quad

	# Actual minimum size
	quad.size = Vector2(0.1, 0.1)
	
	# Put it far away but "in front" of the camera
	newMesh.position = Vector3(0, 0, 0) 
	newMesh.layers = 2
	newMesh.visible = true

	# CRITICAL: Disable shadows to avoid the GLES3 null material check
	newMesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Assign the material
	newMesh.set_surface_override_material(0, mat)
	
	# Add to the current tree (the loading screen itself is safest)
	add_child(newMesh)
	
	# Force a transform update to nudge the renderer to compile the shader
	newMesh.position = Vector3(randf(), randf(), randf()*-100.0)
	
	# Optional: Keep the label updated
	label2.text = "Compiling... " + mat.resource_path.get_file().get_basename()

	# Store the reference so we can delete it later
	_temp_compiler_meshes_to_store.append(newMesh)


# Auxiliary function to encapsulate the clean output, 
# The compilation of prefabs and materials is finished and we want to move on to the main scene
# We took the opportunity to make the second compilation of materials
func _finalize_and_exit() :

	_is_loading_level = true
	label2.text = "Finalizing shaders..."
	
	# Physical disconnection of the signal
	if screenLoaded.is_connected(_launch_loading): screenLoaded.disconnect(_launch_loading)
	
	await _prepare_for_exit()


func _prepare_for_exit() :

	if get_node_or_null("/root/MyLogger") != null : MyLogger.info("LoadingScreen Exiting: " + name + " ... Freeing temporal meshes", 'LoadingScreen.gd', 413, true)
	else : print("[INFO]","LoadingScreen Exiting: " + name + " ... Freeing temporal meshes",'LoadingScreen.gd(413)')

	# We carried out the second compilation
	if GameInstance._materials is Array : await pre_compile_materials(GameInstance._materials)
	
	# Cleaning of temporary meshes
	for node in _temp_compiler_meshes_to_store :
		if is_instance_valid(node): node.queue_free()
	_temp_compiler_meshes_to_store.clear()

	for child in get_children() :
		if child is MeshInstance3D:
			child.queue_free()

	# FINAL LEVEL CHANGE
	LevelManager.load_new_level(_scene_path)

# It is a class with a UI with loading progress bars
# This script enables the preload of prefabs with their meshes
# And also the precompilation of a series of materials of the scene to be load
extends Node3D

var _temp_compilermeshes_to_store: Array[MeshInstance3D] = []

# Indicates which scene and which material of the previous arrays is being loaded
var _scene_index : int = 0
var _material_index : int = 0


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

# Exportas la variable para asignar el archivo .tres desde el Inspector
@export var data_resource: LoadingData

# Variables internas que ahora se alimentan del Resource
# Stores the scene to be loaded once the preload and precompile process has finished
## Stores the scene to be loaded once the preload and precompile process has finished
var _scene_path : String

# All scenes to be loaded one after the other, can be empty (scenes = prefabs)
## All scenes to be loaded one after the other, can be empty (scenes = prefabs)
var _scene_paths_element : String = ""
var _scene_paths : Array[String] = []

# All materials to be compiled, can be empty
## All materials to be compiled, can be empty
var _materials : Array[Material] = []


var meshes_to_store : Dictionary = {}

func _ready() -> void:
	if data_resource:

		_scene_path = data_resource.main_scene_path
		
		# Convertimos los PackedScenes a rutas de String para el ResourceLoader
		for scene in data_resource.prefabs_to_load:
			_scene_paths.append(scene.resource_path)
			
		_materials = data_resource.materials_to_compile

		meshes_to_store = data_resource.meshes_to_store

	# The loading Screen is loaded form the Project settings
	MyLogger.info(name + " Instantiated ... ","loadingScreen.gd",71, true)

	# setting the loading screen camera
	var camera = get_node("Camera3D")
	if camera : camera.make_current()

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
	if meshes_to_store.has(path.get_file().get_basename()) :

		for mesh_data in meshes_to_store[path.get_file().get_basename()] :
			MyLogger.info("The mesh : " + str(mesh_data) + " is being LOADED",'loadingscreen.gd',129,true)

			var mesh_resource: Mesh
		
			# Si guardaste la ruta como String en el Diccionario
			if mesh_data is String:
				mesh_resource = load(mesh_data)

			# Si arrastraste el archivo directamente al Diccionario (es un objeto Mesh)
			elif mesh_data is Mesh:
				mesh_resource = mesh_data
			
			if mesh_resource :
				MyLogger.info("The mesh : " + str(mesh_resource) + " has been stored in memory",'loadingscreen.gd',130,true)
				GameInstance.meshes_to_store.append(mesh_resource)
			else:
				MyLogger.error("Mesh loading failed : " + str(mesh_data), "loadingScreen.gd")


func _load_material(path : String) :
	ResourceLoader.load_threaded_request(path, "", true)
	MyLogger.info("The material : " + path + " is being LOADED,","loadingscreen.gd", 147)





# Function to process the signal emitted
# Just load the next scene or the next material or just load the last scene
var _is_loading_level : bool = false
func _launch_loading() :

	# If we're already leaving, we ignore any residual signals.
	if _is_loading_level : return

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
			if not _is_loading_level : 
				_is_loading_level = true

				label2.text = "Finalizing shaders..."
				await _finalize_and_exit()


		# If it is request a valid material
		if _material_index < _materials.size() :
			
			# We load all the materials one after the other and precompile them
			_load_material(_materials[_material_index].resource_path)

		# If we had scenes to load the new level is loaded when progress 2 bar arrives to 100
		# If we dont have scenes to load the new level is loaded when progress 1 bar arrives to 100
		if (_scene_paths.size() > 0 and progress_bar2.value >= 99.0) or (_scene_paths.size() == 0 and progress_bar1.value >= 99.0) :
			if not _is_loading_level : 
				_is_loading_level = true

				label2.text = "Finalizing shaders..."
				await _finalize_and_exit()

# Executed each frame, main function that handles the loading and compiling process
func _process(delta: float):

	# SECURITY LAYER 2: If the output process started, we stopped processing barcode logic.
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

			# Scene loading in process
			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS :
				_progress1_value = progress[0] * 100
				progress_bar1.value = move_toward(progress_bar1.value, _progress1_value, delta * progress_speed)

			# Scene loading finished
			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED :
				# put the progress bar to 100% so we don't get weird visuals and update the seconf bar progress
				progress_bar1.value = move_toward(progress_bar1.value, 100.0, delta * progress_speed * _scene_paths.size())
				
				# Once the process has finished in the sense that the bar 1 arrives 100% the progress bar 2 moves to the corresponding value
				if progress_bar1.value >= 99.5 :
					
					# If there are no materials the bar 2 goes to 100%
					# If there are materials the bar 2 goes to 50%
					if _materials.size() == 0 :
						_progress2_value = (float) (_scene_index + 1) * 100 / _scene_paths.size()
					else :
						_progress2_value = (float) (_scene_index + 1) * 50 / _scene_paths.size()

					# Only when the second bar arrives the corresponding value it goes to the next step
					if abs(progress_bar2.value - _progress2_value) < 0.1 : # round(progress_bar2.value) == round(_progress2_value) :
						_scene_index += 1
						
						var prefabObj = ResourceLoader.load_threaded_get(_scene_paths_element)
						if prefabObj is PackedScene:
							var key = _scene_paths_element.get_file().get_basename()
							GameInstance._prefabs[key] = prefabObj.instantiate()
							MyLogger.info("Prefab stored: " + key, 'loadingscreen.gd')
							screenLoaded.emit()
						else:
							MyLogger.error("Resource is not a PackedScene: " + _scene_paths_element)

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
				status = ResourceLoader.load_threaded_get_status(_materials[_material_index].resource_path, progress)

				# if is loaded and the progress bar has arrived the target controlled via the progress bar 1, it is used the round function to avoid difference in decimals
				if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED and abs(progress_bar1.value - _progress1_value) < 0.1 :    # and round(progress_bar1.value) == round(_progress1_value) :
					
					# The compilation is being done via the _precompile_material function
					var mat : Material = ResourceLoader.load_threaded_get(_materials[_material_index].resource_path) as Material
					_precompile_material(mat)

					# Once compiled the material we continue with the next one
					_material_index += 1
					screenLoaded.emit()

			# If we dont have any more material and the progress bar has arrived to 100%
			# This is needed because we wait until bar2 arrives 100% once all materials are loaded
			elif progress_bar1.value >= 99.5 :
				screenLoaded.emit()
				
	# If we have none material and the scene preload process has finished
	# No needed because never arrives here due to in this case previously the scene is changed
	else :
		screenLoaded.emit()




# Utility functions for precompiling the materials

func pre_compile_materials(materials_list: Array[Material]):
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
	
	print("Compilación de shaders completada.")


func _precompile_material(mat : Material) -> void :
	if mat == null:
		MyLogger.error("Failed to compile: Material is null", "loadingscreen.gd")
		return # Skip this iteration

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
	newMesh.position = Vector3(randf(), randf(), randf()*-100)
	
	# Optional: Keep the label updated
	label2.text = "Compiling... " + mat.resource_path.get_file().get_basename()

	# Store the reference so we can delete it later
	_temp_compilermeshes_to_store.append(newMesh)


# Función auxiliar para encapsular la salida limpia
func _finalize_and_exit():
	_is_loading_level = true
	label2.text = "Finalizing shaders..."
	
	# CAPA DE SEGURIDAD 3: Desconexión física de la señal
	if screenLoaded.is_connected(_launch_loading):
		screenLoaded.disconnect(_launch_loading)
	
	await _prepare_for_exit()

func _prepare_for_exit() :
	MyLogger.info("LoadingScreen Exiting: " + name + " ... Freeing temporal meshes", 'LoadingScreen.gd', 383, true)

	# Esperamos a la compilación asíncrona
	await pre_compile_materials(GameInstance._materials)
	
	# Limpieza de mallas temporales
	for node in _temp_compilermeshes_to_store :
		if is_instance_valid(node):
			node.queue_free()
	_temp_compilermeshes_to_store.clear()

	for child in get_children() :
		if child is MeshInstance3D:
			child.queue_free()

	# Ejecutamos los eventos de inicio de juego justo antes de cambiar de escena
	GameInstance.start_game_timer()
	EventBus.emit(_ready, EventBus.EVENT.Time_TicToc, 0)
	
	# CAMBIO DE NIVEL FINAL
	LevelManager.load_new_level(_scene_path)

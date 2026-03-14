# Godot-Basic-Loading-Screen-Utility

This utility consists of a scene with progress bar and an image animation and a script that manages scene preloading and shader precompilation.

To do this, the following parameters must be configured:

* _progress_speed : float -> Indicates the speed at which the progress bar completes to indicate the progress of this process. Ultimately, the preload time will determine the elapsed time. With this parameter you can slow down the animation of the preloading and precompilation process.

* _scene_path : String -> Indicates the scene that will be loaded once the preload and precompilation process is complete.

* _scene_paths : Array[String] -> Indicates the list of scenes to be preloaded.

* _materials : Array[String] -> Indicates the list of materials to be precompiled.

  If an autoload mandatorily called GameInstance is created, it may contain the declaration of the variables _scene_path, _scene_paths, and _materials, in which case these will be taken into account instead of those defined in the utility itself. ( _progress_speed can only be configured in the utility)

Note that if you want to reuse the utility to transition between different levels, this is the most convenient way, rather than duplicating the utility, renaming it, and using different copies for each transition.

If the utility is only needed for an initial preload and precompile screen, the most convenient way would be to configure the variables in the utility.

This utility has been tested in https://jocarpe.itch.io/third-person-character-demo

This is a demo in continuous development to test all the components developed and in the process of future development.

It also adds the ability to change characters and view resource consumption via a plugin.

A detailed explanation of how the demo works is available on the itch.io page indicated.

Feel free to check it out in either of its two versions, Windows or Linux.

The code for this demo is available at : [Third Person Character Demo](https://github.com/chemacarceller/Godot-Third-Person-Character-Demo) 

====================================================================================

Esta utilidad consta de una escena con barra de progreso, una animación de imagen y un script que gestiona la precarga de la escena y la precompilación del shader.

Para ello, se deben configurar los siguientes parámetros:

* _progress_speed : float -> Indica la velocidad a la que se completa la barra de progreso para indicar el progreso de este proceso. El tiempo de precarga determinará el tiempo transcurrido. Con este parámetro se puede ralentizar la animación del proceso de precarga y precompilación.

* _scene_path : String -> Indica la escena que se cargará una vez finalizado el proceso de precarga y precompilación.

* _scene_paths : Array[String] -> Indica la lista de escenas que se precargarán.

* _materials : Array[String] -> Indica la lista de materiales que se precompilarán.

Si se crea una carga automática llamada GameInstance, esta puede contener la declaración de las variables _scene_path, _scene_paths y _materials. En este caso, se tendrán en cuenta en lugar de las definidas en la propia utilidad. (_progress_speed solo se puede configurar en la utilidad).

Ten en cuenta que si quieres reutilizar la utilidad para la transición entre diferentes niveles, esta es la forma más conveniente, en lugar de duplicarla, renombrarla y usar diferentes copias para cada transición.

Si la utilidad solo se necesita para una pantalla inicial de precarga y precompilación, la forma más conveniente sería configurar las variables en la utilidad.

Esta utilidad se ha probado en https://jocarpe.itch.io/third-person-character-demo

Esta es una demo en desarrollo continuo para probar todos los componentes desarrollados y en proceso de desarrollo futuro.

También añade la posibilidad de cambiar personajes y ver el consumo de recursos mediante un plugin.

Puedes encontrar una explicación detallada del funcionamiento de la demo en la página de itch.io indicada. 

No dudes en probarlo en cualquiera de sus dos versiones: Windows o Linux.

El código de esta demo lo tienes disponible en : [Third Person Character Demo](https://github.com/chemacarceller/Godot-Third-Person-Character-Demo)

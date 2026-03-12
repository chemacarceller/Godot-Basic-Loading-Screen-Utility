extends TextureRect

var angular_speed : float = PI/1.5

func _ready() -> void:
	var texture_size = texture.get_size()
	pivot_offset = texture_size / 2

func _process(delta):
	rotation += angular_speed * delta

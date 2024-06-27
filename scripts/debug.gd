extends Node2D


func _ready():
	var debug_window_size = Vector2i(1440, 640)
	get_viewport().size = debug_window_size
	get_tree().root.content_scale_size = debug_window_size

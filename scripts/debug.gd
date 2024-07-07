extends Node2D


@export var _server_scene: PackedScene
@export var _client_scene: PackedScene

@export var _client_1: Node2D
@export var _client_2: Node2D
@export var _client_3: Node2D
@export var _client_4: Node2D


func _ready():
	# Windows サイズを変更する
	var debug_window_size = Vector2i(1440, 640)
	get_viewport().size = debug_window_size
	get_tree().root.content_scale_size = debug_window_size

	_client_1.get_node("CanvasLayer").position = Vector2i(0, 0)
	_client_2.get_node("CanvasLayer").position = Vector2i(360, 0)

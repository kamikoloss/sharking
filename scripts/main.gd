extends Node


@export var _server_scene: PackedScene
@export var _client_scene: PackedScene


func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		var server = _server_scene.instantiate()
		add_child(server)
	else:
		var client = _client_scene.instantiate()
		add_child(client)

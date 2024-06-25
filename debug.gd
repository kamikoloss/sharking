extends Node2D


@export var _client_scene: PackedScene 


var _client_position_x_list = [0, 360, 720, 1080]


func _ready():
	get_viewport().size = Vector2i(1440, 640)
	for x in _client_position_x_list:
		var client = _client_scene.instantiate()
		client.position.x = x
		add_child(client)

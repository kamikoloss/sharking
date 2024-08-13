extends Node2D

# Game Nodes
@export var _level: Level
@export var _hero: Hero

# WebSocket
@export var _ws_client: WebSocketClient
@export var _ws_address = "ws://localhost:8000"
@export var _send_interval: float = 0.05
var _send_timer: float = 0.0

# UI
@export var _button_center: Button

# Debug
@export var _debug_label_state: Label
@export var _debug_label_charge: Label


func _ready() -> void:
	_ws_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_ws_client.connection_closed.connect(_on_web_socket_client_connection_closed)
	_ws_client.message_received.connect(_on_web_socket_client_message_received)

	_button_center.button_down.connect(_on_center_button_down)
	_button_center.button_up.connect(_on_center_button_up)


func _process(delta: float) -> void:
	_process_refresh_debug(delta)


func _on_web_socket_client_connected_to_server():
	print("[Client] Connected to server!")


func _on_web_socket_client_connection_closed():
	print("[Client] Connection closed.")


func _on_web_socket_client_message_received(message: Variant):
	print("[Client] Message received from server. Message: %s" % [message])
	match message["type"] as Message.MessageType:
		Message.MessageType.PLAYER_CONNECTED:
			pass
		Message.MessageType.OTHER_PLAYER_CONNECTED:
			pass
		Message.MessageType.OTHER_PLAYER_DISCONNECTED:
			pass
		Message.MessageType.HERO_SPAWNED:
			pass
		Message.MessageType.HERO_MOVE_STARTED:
			pass
		Message.MessageType.HERO_MOVE_FINISHED:
			pass


func _on_center_button_down():
	_hero.enter_charge()


func _on_center_button_up():
	_hero.exit_charge()


func _connect_to_server():
	var _error = _ws_client.connect_to_url(_ws_address)
	if _error != OK:
		print("[Client] connection failed. (%s)" % error_string(_error))


# Debug
func _process_refresh_debug(_delta: float) -> void:
	_debug_label_state.text = "STT:%s" % Hero.MoveState.keys()[_hero.move_state]
	_debug_label_charge.text = "CHR:%s" % snapped(_hero.charge, 0.01)

class_name Client
extends Node2D


enum GameState {
	LOBBY, # 接続待ち
	GAME, # 接続中
}


var _game_state = GameState.LOBBY

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

	_button_center.text = "CONNECT"


func _process(delta: float) -> void:
	_process_refresh_debug(delta)


func _on_web_socket_client_connected_to_server():
	print("[Client] Connected to server!")


func _on_web_socket_client_connection_closed():
	print("[Client] Connection closed.")


func _on_web_socket_client_message_received(message: Variant):
	print("[Client] Message received from server. Message: %s" % [message])
	match message["type"] as Message.MessageType:
		# 自プレイヤーが接続したとき
		Message.MessageType.PLAYER_CONNECTED:
			# Server から受け取った EXP 情報を同期する
			var exps_data = message["exps"]
			var exps = []
			for exp in exps_data:
				var _exp = Exp.new(exp["point"], exp["position"])
				exps.append(_exp)
			print("[Client/Debug] exps %s" % [exps])
			_level.spawn_exps(exps)
		# 他プレイヤーが接続したとき
		Message.MessageType.OTHER_PLAYER_CONNECTED:
			pass
		#
		Message.MessageType.OTHER_PLAYER_DISCONNECTED:
			pass
		#
		Message.MessageType.HERO_SPAWNED:
			pass
		#
		Message.MessageType.HERO_MOVE_STARTED:
			pass
		#
		Message.MessageType.HERO_MOVE_FINISHED:
			pass


func _on_center_button_down():
	match _game_state:
		GameState.LOBBY:
			_connect_to_server()
		GameState.GAME:
			_hero.enter_charge()


func _on_center_button_up():
	match _game_state:
		GameState.GAME:
			_hero.exit_charge()


func _connect_to_server():
	var _error = _ws_client.connect_to_url(_ws_address)
	if _error == OK:
		_game_state = GameState.GAME
	else:
		print("[Client] connection failed. (%s)" % error_string(_error))


# Debug
func _process_refresh_debug(_delta: float) -> void:
	_debug_label_state.text = "STT:%s" % Hero.MoveState.keys()[_hero.move_state]
	_debug_label_charge.text = "CHR:%s" % snapped(_hero.charge, 0.01)

class_name Client
extends Node2D


enum GameMode {
	TITLE, # 起動中/接続待ち
	LOBBY, # 接続中/スポーン待ち
	GAME, # ゲーム中
}


var _game_mode = GameMode.TITLE
var _peer_id = -1

@export var _level: Level

# TODO: Hero 系の管理は Node 分ける
@export var _hero_scene: PackedScene
var _main_hero: Hero
var _other_heros: Dictionary = {} # { ID: Hero, ... }
@export var _other_heros_parent_node: Node2D

# WebSocket
@export var _ws_client: WebSocketClient
@export var _ws_address = "ws://localhost:8000"
@export var _send_interval: float = 0.05
var _send_timer: float = 0.0

# UI
@export var _button_center: Button

# Debug
@export var _debug_label_game_mode: Label
@export var _debug_label_peer_id: Label
@export var _debug_label_hero_move_state: Label
@export var _debug_label_hero_charge: Label


func _ready() -> void:
	_ws_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_ws_client.connection_closed.connect(_on_web_socket_client_connection_closed)
	_ws_client.message_received.connect(_on_web_socket_client_message_received)

	_button_center.button_down.connect(_on_center_button_down)
	_button_center.button_up.connect(_on_center_button_up)
	_change_game_mode(GameMode.TITLE)


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
			# 自身の Peer ID を保持する
			_peer_id = message["pid"]
			# EXP 情報を同期する
			var exps = []
			for exp in message["exps"]:
				exps.append(Exp.new(exp["pt"], exp["pos"]))
			_level.spawn_exps(exps)
			# 他 Hero 情報を同期する
			for hero in message["heros"]:
				var hero_instance = _hero_scene.instantiate()
				hero_instance.id = hero["id"]
				hero_instance.exp_point = hero["exp"]
				hero_instance.position = hero["pos"]
				_other_heros_parent_node.add_child(hero_instance)
				_other_heros[hero_instance.id] = hero_instance
		# 他プレイヤーが接続したとき
		Message.MessageType.OTHER_PLAYER_CONNECTED:
			pass
		# 他プレイヤーが切断したとき
		Message.MessageType.OTHER_PLAYER_DISCONNECTED:
			pass
		# Hero が生まれたとき
		Message.MessageType.HERO_SPAWNED:
			var hero_instance = _hero_scene.instantiate()
			hero_instance.id = message["pid"]
			hero_instance.exp_point = 0
			hero_instance.position = message["pos"]
			_other_heros_parent_node.add_child(hero_instance)
			_other_heros[hero_instance.id] = hero_instance
		# Hero が移動開始したとき
		Message.MessageType.HERO_MOVE_STARTED:
			pass
		# Hero が移動終了したとき
		Message.MessageType.HERO_MOVE_FINISHED:
			pass
		# Hero がダメージを受けたとき (死んだときも含む)
		Message.MessageType.HERO_DAMAGED:
			pass
		# EXP が生まれたとき
		Message.MessageType.EXP_SPAWNED:
			pass


func _on_center_button_down():
	match _game_mode:
		GameMode.TITLE:
			_connect_to_server()
		GameMode.LOBBY:
			# TODO: スポーン位置選択
			_spawn_main_hero()
		GameMode.GAME:
			if _main_hero:
				_main_hero.enter_charge()


func _on_center_button_up():
	match _game_mode:
		GameMode.GAME:
			if _main_hero:
				_main_hero.exit_charge()


func _connect_to_server():
	var _error = _ws_client.connect_to_url(_ws_address)
	if _error == OK:
		_change_game_mode(GameMode.LOBBY)
	else:
		print("[Client] connection failed. (%s)" % error_string(_error))


# Server にメッセージを送信する
func _send_message(message: Variant) -> void:
	_ws_client.send(message)


func _change_game_mode(to: GameMode) -> void:
	_game_mode = to
	match to:
		GameMode.TITLE:
			_button_center.text = "CONNECT"
		GameMode.LOBBY:
			_button_center.text = "SPAWN"
		GameMode.GAME:
			_button_center.text = "MOVE"


func _spawn_main_hero() -> void:
	if _peer_id < 0:
		print("[Client] failed to spawn main hero.")
		return

	var hero_instance = _hero_scene.instantiate()
	hero_instance.id = _peer_id
	hero_instance.exp_point = 0
	hero_instance.position = Vector2.ZERO # TODO
	hero_instance.is_local = true
	add_child(hero_instance)
	_main_hero = hero_instance

	var msg = {
		"type": Message.MessageType.HERO_SPAWNED,
		"pid": _peer_id,
		"pos": _main_hero.position,
	}
	_send_message(msg)

	_change_game_mode(GameMode.GAME)


# Debug
func _process_refresh_debug(_delta: float) -> void:
	_debug_label_game_mode.text = "MOD:%s" % GameMode.keys()[_game_mode]
	_debug_label_peer_id.text = "PID:%s" % _peer_id
	if _main_hero:
		_debug_label_hero_move_state.text = "MST:%s" % Hero.MoveState.keys()[_main_hero.move_state]
		_debug_label_hero_charge.text = "CHR:%s" % snapped(_main_hero.charge, 0.01)

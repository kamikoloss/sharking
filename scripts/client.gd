class_name Client
extends Node2D


enum GameMode {
	TITLE, # 起動中/接続待ち
	LOBBY, # 接続中/スポーン待ち
	GAME, # ゲーム中
}


var _game_mode = GameMode.TITLE:
	set(value):
		_game_mode = value
		match value:
			GameMode.TITLE:
				_button_center.text = "CONNECT"
			GameMode.LOBBY:
				_button_center.text = "SPAWN"
			GameMode.GAME:
				_button_center.text = "MOVE"
var _peer_id = -1

# WebSocket
@export var _ws_client: WebSocketClient
@export var _ws_address = "ws://localhost:8000"
@export var _send_interval: float = 0.05

# Game Nodes
@export var _level: Level
@export var _hero_scene: PackedScene
var _main_hero: Hero

# UI
@export var _button_center: Button
@export var _button_left: Button
@export var _button_right: Button

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
	_button_left.button_down.connect(_on_left_button_down)
	_button_right.button_down.connect(_on_right_button_down)

	# 初期処理
	_level.is_client = true
	_game_mode = GameMode.TITLE


func _process(delta: float) -> void:
	_process_refresh_debug(delta)


func _on_web_socket_client_connected_to_server() -> void:
	print("[Client] Connected to server!")


func _on_web_socket_client_connection_closed() -> void:
	print("[Client] Connection closed.")


func _on_web_socket_client_message_received(message: Variant) -> void:
	#print("[Client] Message received from server. Message: %s" % [message])

	match message["type"] as Message.MessageType:
		# 自プレイヤーが接続したとき
		Message.MessageType.PLAYER_CONNECTED:
			# 自身の Peer ID を保持する
			_peer_id = message["pid"]
			# EXP 情報を同期する
			for exp in message["exps"]:
				_level.spawn_exp(exp["id"], exp["pt"], exp["pos"])
			# 他 Hero 情報を同期する
			for hero in message["heros"]:
				_level.spawn_hero(hero["id"])
				_level.update_hero(hero["id"], hero["exp"], hero["hlt"], hero["pos"])
		# 他プレイヤーが接続したとき
		Message.MessageType.OTHER_PLAYER_CONNECTED:
			pass
		# 他プレイヤーが切断したとき
		Message.MessageType.OTHER_PLAYER_DISCONNECTED:
			_level.despawn_hero(message["pid"]) # 死んだときと同じ
		# Hero が生成されたとき
		Message.MessageType.HERO_SPAWNED: 
			_level.spawn_hero(message["pid"])
			_level.update_hero(message["pid"], message["exp"], message["hlt"], message["pos"])
		# Hero が移動開始したとき
		Message.MessageType.HERO_MOVE_STARTED:
			_level.update_hero(message["pid"], message["exp"], message["hlt"], message["pos"])
			_level.move_hero(message["pid"], message["chr"], message["dest"], message["dur"])
		# Hero が移動終了したとき
		Message.MessageType.HERO_MOVE_STOPPED:
			_level.update_hero(message["pid"], message["exp"], message["hlt"], message["pos"])
			for exp_id in message["expids"]:
				_level.despawn_exp(exp_id)
		# Hero がダメージを受けたとき
		Message.MessageType.HERO_DAMAGED:
			_level.update_hero(message["pid"], message["exp"], message["hlt"], message["pos"])
		# Hero が死んだとき
		Message.MessageType.HERO_DIED:
			_level.despawn_hero(message["pid"])
		# EXP が生成されたとき
		Message.MessageType.EXP_SPAWNED:
			for exp in message["exps"]:
				_level.spawn_exp(exp["id"], exp["pt"], exp["pos"])


func _on_center_button_down() -> void:
	match _game_mode:
		GameMode.TITLE:
			_connect_to_server()
		GameMode.LOBBY:
			# TODO: スポーン位置選択
			_spawn_hero()
		GameMode.GAME:
			if _main_hero:
				_main_hero.enter_charge()


func _on_center_button_up() -> void:
	match _game_mode:
		GameMode.GAME:
			if _main_hero:
				_main_hero.exit_charge()


func _on_left_button_down() -> void:
	pass


func _on_right_button_down() -> void:
	pass


func _connect_to_server() -> void:
	var _error = _ws_client.connect_to_url(_ws_address)
	if _error == OK:
		_game_mode = GameMode.LOBBY
	else:
		print("[Client] connection failed. (%s)" % error_string(_error))


# Server にメッセージを送信する
func _send_message(message: Variant) -> void:
	_ws_client.send(message)


func _spawn_hero() -> void:
	# Peer ID を持っていない場合 (接続できていない場合)
	if _peer_id < 0:
		print("[Client] failed to spawn main hero.")
		return
	# 一度死んだあと = 再生成の場合
	if _main_hero:
		_main_hero.queue_free()

	var hero_instance = _hero_scene.instantiate()
	hero_instance.id = _peer_id
	hero_instance.is_client = true
	hero_instance.is_local = true
	hero_instance.exp_point = 0
	hero_instance.position = Vector2.ZERO # TODO
	add_child(hero_instance)

	_main_hero = hero_instance
	_main_hero.move_started.connect(_on_hero_move_started)
	_main_hero.move_stopped.connect(_on_hero_move_stopped)
	_main_hero.damaged.connect(_on_hero_damaged)
	_main_hero.died.connect(_on_hero_died)

	var msg = {
		# 基本
		"type": Message.MessageType.HERO_SPAWNED,
		"pid": _peer_id,
		# Hero
		"exp": _main_hero.exp_point,
		"hlt": _main_hero.health_point,
		"pos": _main_hero.position,
	}
	_send_message(msg)

	_game_mode = GameMode.GAME


func _on_hero_move_started(charge: float, dest_position: Vector2, move_duration: float) -> void:
	var msg = {
		# 基本
		"type": Message.MessageType.HERO_MOVE_STARTED,
		"pid": _peer_id,
		# Hero
		"exp": _main_hero.exp_point,
		"hlt": _main_hero.health_point,
		"pos": _main_hero.position,
		# 移動開始
		"chr": charge,
		"dest": dest_position,
		"dur": move_duration,
	}
	_send_message(msg)


func _on_hero_move_stopped() -> void:
	var msg = {
		# 基本
		"type": Message.MessageType.HERO_MOVE_STOPPED,
		"pid": _peer_id,
		# Hero
		"exp": _main_hero.exp_point,
		"hlt": _main_hero.health_point,
		"pos": _main_hero.position,
		# 移動終了
		"expids": _main_hero.got_exp_ids,
	}
	_send_message(msg)


func _on_hero_damaged() -> void:
	var msg = {
		# 基本
		"type": Message.MessageType.HERO_DAMAGED,
		"pid": _peer_id,
		# Hero
		"exp": _main_hero.exp_point,
		"hlt": _main_hero.health_point,
		"pos": _main_hero.position,
	}
	_send_message(msg)


func _on_hero_died() -> void:
	var msg = {
		# 基本
		"type": Message.MessageType.HERO_DAMAGED,
		"pid": _peer_id,
		# Hero
		"exp": _main_hero.exp_point,
		"hlt": _main_hero.health_point,
		"pos": _main_hero.position,
	}
	_send_message(msg)

	_game_mode = GameMode.LOBBY


# Debug
func _process_refresh_debug(_delta: float) -> void:
	_debug_label_game_mode.text = "MOD:%s" % GameMode.keys()[_game_mode]
	_debug_label_peer_id.text = "PID:%s" % _peer_id
	if _main_hero:
		_debug_label_hero_move_state.text = "MST:%s" % Hero.MoveState.keys()[_main_hero.move_state]
		_debug_label_hero_charge.text = "CHR:%s" % snapped(_main_hero.charge, 0.01)

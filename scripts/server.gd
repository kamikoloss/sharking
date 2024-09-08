class_name Server
extends Node2D


# WebSocket
@export var _ws_server: WebSocketServer
var _ws_port: int = 8000

# Game Nodes
@export var _level: Level

var _respawn_exps_timer: float = 0.0 # 最後に EXP を復活させてから何秒経ったかのタイマー
var _respawn_exps_cooltime: float = 5.0 # 何秒ごとに EXP が復活するか


func _ready() -> void:
	_ws_server.client_connected.connect(_on_web_socket_server_client_connected)
	_ws_server.client_disconnected.connect(_on_web_socket_server_client_disconnected)
	_ws_server.message_received.connect(_on_web_socket_server_message_received)

	# 初期処理
	_level.is_client = false
	_spawn_exps_to_limit()

	# サーバー開始
	_parse_args()
	_start_server()

	print("[Server] _ready")


func _process(delta: float) -> void:
	_process_respawn_exps(delta)


func _on_web_socket_server_client_connected(peer_id: int) -> void:
	print("[Server] New peer connected. ID: ", peer_id)

	# 接続した Peer に現在の状況を共有する
	var exps_data = []
	var heros_data = []
	for exp in _level.exps_on_level.values():
		exps_data.append({ "id": exp.id, "pt": exp.point, "pos": exp.position })
	for hero in _level.heros_on_level.values():
		heros_data.append({ "id": hero.id, "exp": hero.exp_point, "hlt": hero.health_point, "pos": hero.position })
	var msg_pc = {
		"type": Message.MessageType.PLAYER_CONNECTED,
		"pid": peer_id,
		"exps": exps_data,
		"heros": heros_data,
	}
	_send_message_to_peer(msg_pc, peer_id)

	# 接続中の Peer に接続した Peer を共有する
	var msg_opc = {
		"type": Message.MessageType.OTHER_PLAYER_CONNECTED,
		"pid": peer_id,
	}
	_send_message_to_peers(msg_opc, peer_id)


func _on_web_socket_server_client_disconnected(peer_id: int) -> void:
	# 接続中の Peer に切断した Peer を共有する
	print("[Server] Peer disconnected. ID: ", peer_id)
	var msg = {
		"type": Message.MessageType.OTHER_PLAYER_DISCONNECTED,
		"pid": peer_id,
	}
	_send_message_to_peers(msg, peer_id)

	# Server 上の Hero 情報を更新する
	_level.despawn_hero(peer_id)


func _on_web_socket_server_message_received(peer_id: int, message: Variant) -> void:
	print("[Server] Message received from client. ID: %d, Message: %s" % [peer_id, message])

	# 送信者以外のすべての Peer に共有する
	if message["type"] in Message.THROUGH_MESSAGE_TYPES:
		_send_message_to_peers(message, peer_id)

	# Server 上の情報を更新する
	match message["type"]:
		# Hero が生成されたとき
		Message.MessageType.HERO_SPAWNED:
			_level.spawn_hero(message["pid"])
			_level.update_hero(message["pid"], message["exp"], message["hlt"], message["pos"])
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


func _parse_args() -> void:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if "=" in arg:
			var key_value = arg.split("=")
			# --port
			if key_value[0] == "--port":
				_ws_port = int(key_value[1])


func _start_server() -> void:
	_ws_server.listen(_ws_port)
	print("[Server] listen port: %s" % _ws_port)


# 特定の Peer にメッセージを送信する
func _send_message_to_peer(message: Variant, peer_id: int) -> void:
	_ws_server.send(peer_id, message)


# 接続中のすべての Peer にメッセージを一括送信する
# except_peer_id: 一括送信先から除く Peer ID
func _send_message_to_peers(message: Variant, except_peer_id: int = 0) -> void:
	for peer_id in _ws_server.peers.keys():
		if peer_id != except_peer_id:
			_send_message_to_peer(message, peer_id)


func _process_respawn_exps(delta: float) -> void:
	_respawn_exps_timer += delta
	if _respawn_exps_cooltime < _respawn_exps_timer:
		_respawn_exps_timer = 0.0
		_spawn_exps_to_limit()


func _spawn_exps_to_limit() -> void:
	var exps = _level.spawn_exps_to_limit()

	var exps_data = []
	var heros_data = []
	for exp in exps:
		exps_data.append({ "id": exp.id, "pt": exp.point, "pos": exp.position })
	for hero in _level.heros_on_level.values():
		heros_data.append({ "id": hero.id, "exp": hero.exp_point, "hlt": hero.health_point, "pos": hero.position })

	var msg = {
		"type": Message.MessageType.EXP_SPAWNED,
		"exps": exps_data,
		"heros": heros_data,
	}
	_send_message_to_peers(msg)

class_name Server
extends Node2D


# Game Nodes
@export var _level: Level

# WebSocket
@export var _ws_server: WebSocketServer
@export var _ws_port: int = 8000
@export var _send_interval: float = 0.05
var _send_timer: float = 0.0


func _ready() -> void:
	_ws_server.client_connected.connect(_on_web_socket_server_client_connected)
	_ws_server.client_disconnected.connect(_on_web_socket_server_client_disconnected)
	_ws_server.message_received.connect(_on_web_socket_server_message_received)

	# EXP 初期生成
	var exps = _level.get_exps_to_limit()
	_level.spawn_exps(exps)

	# サーバー開始
	_parse_args()
	_start_server()


func _on_web_socket_server_client_connected(peer_id: int):
	print("[Server] New peer connected. ID: ", peer_id)
	# 新しく接続した Peer に現在の状況を共有する
	var exps_data = []
	for exp in _level.exps_on_level.values():
		exps_data.append({ "id": exp.id, "pt": exp.point, "pos": exp.position })
	var heros_data = []
	for hero in _level.heros_on_level.values():
		heros_data.append({ "id": hero.id, "exp": hero.exp_point, "pos": hero.position })
	var msg_pc = {
		"type": Message.MessageType.PLAYER_CONNECTED,
		"pid": peer_id,
		"exps": exps_data,
		"heros": heros_data,
	}
	_send_message_to_peer(msg_pc, peer_id)
	# 接続済みの Peer に新しく接続した Peer を共有する
	var msg_opc = {
		"type": Message.MessageType.OTHER_PLAYER_CONNECTED,
		"pid": peer_id,
	}
	_send_message_to_peers(msg_opc, peer_id)


func _on_web_socket_server_client_disconnected(peer_id: int):
	print("[Server] Peer disconnected. ID: ", peer_id)
	var msg = {
		"type": Message.MessageType.OTHER_PLAYER_CONNECTED,
		"pid": peer_id,
	}
	_send_message_to_peers(msg, peer_id)


func _on_web_socket_server_message_received(peer_id: int, message: Variant):
	#print("[Server] Message received from client. ID: %d, Message: %s" % [peer_id, message])
	var message_type = message["type"] as Message.MessageType

	# 送信者以外のすべての Peer に共有する
	if message_type in Message.THROUGH_MESSAGE_TYPES:
		_send_message_to_peers(message, peer_id)

		# Server 上の Hero 情報を更新する
		if message_type == Message.MessageType.HERO_SPAWNED:
			_level.spawn_hero(message["pid"])
			_level.update_hero(message["pid"], 0, message["pos"])
		else:
			_level.update_hero(message["pid"], message["exp"], message["pos"])


func _parse_args() -> void:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if "=" in arg:
			var key_value = arg.split("=")
			# --tick-rate
			if key_value[0] == "--tick-rate":
				_send_interval = 1.0 / float(key_value[1])


func _start_server() -> void:
	_ws_server.listen(_ws_port)
	print("[Server] listen port: %s" % _ws_port)
	print("[Server] send interval: %s s" % _send_interval)


# 特定の Peer にメッセージを送信する
func _send_message_to_peer(message: Variant, peer_id: int) -> void:
	_ws_server.send(peer_id, message)


# 接続中のすべての Peer にメッセージを一括送信する
func _send_message_to_peers(message: Variant, except_peer_id: int = 0) -> void:
	for peer_id in _ws_server.peers:
		if except_peer_id != 0 and peer_id != except_peer_id:
			_ws_server.send(peer_id, message)

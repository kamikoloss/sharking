extends Node2D


var heros: Dictionary = {} # { Peer ID: Hero, ... }
var exps: Dictionary = {} # { Inst ID: Exp, ... }


# WebSocket
@export var _ws_server: WebSocketServer
@export var _ws_port: int = 8000
@export var _send_interval: float = 0.05
var _send_timer: float = 0.0


func _ready() -> void:
	_ws_server.client_connected.connect(_on_web_socket_server_client_connected)
	_ws_server.client_disconnected.connect(_on_web_socket_server_client_disconnected)
	_ws_server.message_received.connect(_on_web_socket_server_message_received)

	_parse_args()
	_start_server()


func _process(delta: float) -> void:
	#_process_send(delta)
	pass


func _on_web_socket_server_client_connected(peer_id: int):
	print("[Server] New peer connected. ID: ", peer_id)
	# 接続した本人に送信する
	_ws_server.send(peer_id, ServerMessage.PlayerConnected.new(peer_id, heros, exps))
	# 接続した本人以外に送信する
	for pid in _ws_server.peers:
		if pid != peer_id:
			_ws_server.send(pid, ServerMessage.OtherPlayerConnected.new(peer_id))


func _on_web_socket_server_client_disconnected(peer_id: int):
	print("[Server] Peer disconnected. ID: ", peer_id)
	# 切断した本人には送信できない
	# 切断した本人以外に送信する
	for pid in _ws_server.peers:
		if pid != peer_id:
			_ws_server.send(pid, ServerMessage.OtherPlayerDisconnected.new(peer_id))


func _on_web_socket_server_message_received(peer_id: int , message: Variant):
	print("[Server] Message received from client. ID: %d, Message: %s" % [peer_id, message])


func _parse_args() -> void:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if "=" in arg:
			var key_value = arg.split("=")
			# --tick-rate
			if key_value[0] == "--tick-rate":
				_send_interval = 1.0 / float(key_value[1])
		else:
			pass


func _start_server() -> void:
	_ws_server.listen(_ws_port)
	print("[Server] listen port: %s" % _ws_port)
	print("[Server] send interval: %s s" % _send_interval)


# 接続中の Client にデータを一括送信する
func _process_send(delta: float) -> void:
	if _ws_server.peers.is_empty():
		return
	_send_timer += delta
	if _send_timer < _send_interval:
		return
	_send_timer = 0.0

	for peer_id in _ws_server.peers:
		var message = {}
		_ws_server.send(peer_id, message)

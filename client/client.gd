extends Node2D


# WebSocket
@export var _ws_client: WebSocketClient
@export var _ws_address = "ws://localhost:8000"
@export var _send_interval: float = 0.05
var _send_timer: float = 0.0

# Ping
@export var _ping_current_label: Label
@export var _ping_average_label: Label
@export var _ping_refresh_interval: float = 0.25
var _ping_refresh_timer: float = 0.0
var _recent_ping_list: Array[float] = []
var _recent_ping_list_max_size: int = 50


func _ready() -> void:
	_ws_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_ws_client.connection_closed.connect(_on_web_socket_client_connection_closed)
	_ws_client.message_received.connect(_on_web_socket_client_message_received)


func _process(delta: float) -> void:
	_process_refresh_ping(delta)


func _on_web_socket_client_connected_to_server():
	print("[Client] Connected to server!")


func _on_web_socket_client_connection_closed():
	print("[Client] Connection closed.")


func _on_web_socket_client_message_received(message: Variant):
	print("[Client] Message received from server. Message: %s" % [message])


func _connect_to_server():
	var _error = _ws_client.connect_to_url(_ws_address)
	if _error != OK:
		print("[Client] connection failed. (%s)" % error_string(_error))


# Ping の表示を更新する
func _process_refresh_ping(delta: float) -> void:
	if _recent_ping_list.is_empty():
		return
	_ping_refresh_timer += delta
	if _ping_refresh_timer < _ping_refresh_interval:
		return
	_ping_refresh_timer = 0.0

	var ping_sum = _recent_ping_list.reduce(func(a, n): return a + n, 0.0)
	var ping_avg = ping_sum / _recent_ping_list.size()
	_ping_current_label.text = "Current: %s ms" % str(snappedf(_recent_ping_list[-1] * 1000, 0.01))
	_ping_average_label.text = "Average: %s ms" % str(snappedf(ping_avg * 1000, 0.01))

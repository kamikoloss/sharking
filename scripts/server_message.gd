extends Node
class_name ServerMessage
# Server -> Client のメッセージ


# メッセージのタイプ
enum MessageType {
	PING,
	PLAYER_CONNECTED,
	#PLAYER_DISCONNECTED,
	OTHER_PLAYER_CONNECTED,
	OTHER_PLAYER_DISCONNECTED,
}


# Ping を計測するとき
class Ping:
	var type: MessageType = MessageType.PING
	var id: String # 識別子
	var time: int # Client から送信された Unixtime (そのまま返す)
	func _init(id: String, time: int):
		self.id = id
		self.time = time


# 自プレイヤーが接続したとき
class PlayerConnected:
	var type: MessageType = MessageType.PLAYER_CONNECTED
	var peer_id: int # 接続したプレイヤーの Peer ID
	var heros: Dictionary # すでに接続していた他プレイヤーの情報 { Peer ID: Hero, ... }
	var exps: Dictionary # 経験値の情報 { Exp ID: Exp, ... }
	func _init(peer_id: int, heros: Dictionary, exps: Dictionary):
		self.peer_id = peer_id
		self.heros = heros
		self.exps = exps


# 自プレイヤーが切断したとき
# 切断したプレイヤーには届かないのでメッセージはない


# 他プレイヤーが接続したとき
class OtherPlayerConnected:
	var type: MessageType = MessageType.OTHER_PLAYER_CONNECTED
	var peer_id: int # 接続した他プレイヤーの Peer ID
	func _init(peer_id: int):
		self.peer_id = peer_id


# 他プレイヤーが切断したとき
class OtherPlayerDisconnected:
	var type: MessageType = MessageType.OTHER_PLAYER_DISCONNECTED
	var peer_id: int # 切断した他プレイヤーの Peer ID
	func _init(peer_id: int):
		self.peer_id = peer_id

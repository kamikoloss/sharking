class_name Message
extends Node
# Server と Client がやり取りするメッセージ


# メッセージのタイプ
# TODO: Class があるならいらない？
enum MessageType {
	PING,
	PLAYER_CONNECTED,
	OTHER_PLAYER_CONNECTED,
	OTHER_PLAYER_DISCONNECTED,
	HERO_SPAWNED,
	HERO_MOVE_STARTED,
	HERO_MOVE_FINISHED,
	#HERO_DAMAGED,
	#HERO_DEAD,
	#EXP_SPAWNED,
}


var type: MessageType
var peer_id: int # アクションを起こした Peer ID


# アクションを起こした Client の Peer ID を設定する
# TODO: CPU は疑似的な Peer ID を設定する
func set_peer_id(peer_id: int) -> void:
	self.peer_id = peer_id


# (CSC) Ping を計測するとき
class Ping extends Message:
	var ping_id: String # 時間差を計算するための識別子
	var time: int # Client の Unixtime
	func _init(ping_id: String, time: int) -> void:
		type = MessageType.PING
		self.ping_id = ping_id
		self.time = time


# (SC) 自プレイヤーが接続したとき
class PlayerConnected extends Message:
	var heros: Dictionary # すでに存在する他プレイヤーの情報 { ID: Hero, ... }
	var exps: Dictionary # EXP の情報 { ID: Exp, ... }
	func _init(heros: Dictionary, exps: Dictionary) -> void:
		type = MessageType.PLAYER_CONNECTED
		self.heros = heros
		self.exps = exps


# (SC) 他プレイヤーが接続したとき
class OtherPlayerConnected extends Message:
	var hero: Hero # 接続した他プレイヤ―の情報
	func _init(hero: Hero) -> void:
		type = MessageType.OTHER_PLAYER_CONNECTED
		self.hero = hero


# (SC) 他プレイヤーが切断したとき
class OtherPlayerDisconnected extends Message:
	func _init(peer_id: int) -> void:
		type = MessageType.OTHER_PLAYER_DISCONNECTED


# (CSC) Hero が Level に生まれたとき
class HeroSpanwed extends Message:
	var position: Vector2
	func _init(position: Vector2) -> void:
		type = MessageType.HERO_SPAWNED
		self.position = position


# (CSC) Hero が移動を開始したとき
class HeroMoveStarted extends Message:
	var direction: float # 移動方向 (deg)
	var charge: float # 移動タメ
	func _init(direction: float, charge: float) -> void:
		type = MessageType.HERO_MOVE_STARTED
		self.direction = direction
		self.charge = charge


# (CSC) Hero が移動を終了したとき
class HeroMoveFinished extends Message:
	var final_position: Vector2 # 最終的な座標 (調整用)
	var got_exps: Dictionary # 移動で取得した EXP
	func _init(final_position: Vector2, got_exps: Dictionary) -> void:
		type = MessageType.HERO_MOVE_FINISHED
		self.final_position = final_position
		self.got_exps = got_exps

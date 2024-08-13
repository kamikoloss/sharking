class_name Message
extends Node
# Server と Client がやり取りするメッセージ


# メッセージのタイプ
# TODO: Class があるならいらない？
enum MessageType {
	PLAYER_CONNECTED,
	OTHER_PLAYER_CONNECTED,
	OTHER_PLAYER_DISCONNECTED,
	HERO_SPAWNED,
	HERO_MOVE_STARTED,
	HERO_MOVE_FINISHED,
	HERO_DAMAGED,
	HERO_DEAD,
	EXP_SPAWNED,
}


# Server に送信されたメッセージを送信者以外のすべての Peer に共有するタイプ
const THROUGH_MESSAGE_TYPES: Array[MessageType] = [
	MessageType.HERO_SPAWNED,
	MessageType.HERO_MOVE_STARTED,
	MessageType.HERO_MOVE_FINISHED,
	MessageType.HERO_DAMAGED,
	MessageType.HERO_DEAD,
]


# すべての Message に共通するプロパティ
var type: MessageType
var peer_id: int # アクションを起こした Peer の ID


# (SC) 自プレイヤーが接続したとき
class PlayerConnected extends Message:
	var heros: Dictionary # すでに存在する他プレイヤーの情報 { ID: Hero, ... }
	var exps: Dictionary # EXP の情報 { ID: Exp, ... }
	func _init(peer_id: int, heros: Dictionary, exps: Dictionary) -> void:
		self.type = MessageType.PLAYER_CONNECTED
		self.peer_id = peer_id
		self.heros = heros
		self.exps = exps


# (SC) 他プレイヤーが接続したとき
class OtherPlayerConnected extends Message:
	func _init(peer_id: int) -> void:
		self.type = MessageType.OTHER_PLAYER_CONNECTED
		self.peer_id = peer_id


# (SC) 他プレイヤーが切断したとき
class OtherPlayerDisconnected extends Message:
	func _init(peer_id: int) -> void:
		self.type = MessageType.OTHER_PLAYER_DISCONNECTED
		self.peer_id = peer_id


# (CSC) Hero が Level に生まれたとき
class HeroSpanwed extends Message:
	var hero: Hero
	var position: Vector2 # スポーンした座標
	func _init(peer_id: int, hero: Hero, position: Vector2) -> void:
		self.type = MessageType.HERO_SPAWNED
		self.peer_id = peer_id
		self.hero = hero
		self.position = position


# (CSC) Hero が移動を開始したとき
class HeroMoveStarted extends Message:
	var direction: float # 移動方向 (deg)
	var charge: float # 移動タメ (0.0-1.0)
	func _init(peer_id: int, direction: float, charge: float) -> void:
		self.type = MessageType.HERO_MOVE_STARTED
		self.peer_id = peer_id
		self.direction = direction
		self.charge = charge


# (CSC) Hero が移動を終了したとき
class HeroMoveFinished extends Message:
	var final_position: Vector2 # 停止した座標 (調整用)
	var got_exp_ids: Array[int] # 移動で取得した EXP の ID のリスト
	func _init(peer_id: int, final_position: Vector2, got_exp_ids: Array[int]) -> void:
		self.type = MessageType.HERO_MOVE_FINISHED
		self.peer_id = peer_id
		self.final_position = final_position
		self.got_exp_ids = got_exp_ids

class_name Message
extends Node


# メッセージのタイプ
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

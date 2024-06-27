extends Node


# Server から Clinet に送信するメッセージのタイプ
enum MessageType {
	NONE,
	PLAYER_CONNECTED,
	PLAYER_DISCONNECTED,
	OTHER_PLAYER_CONNECTED,
	OTHER_PLAYER_DISCONNECTED,
}

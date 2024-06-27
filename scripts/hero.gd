extends RigidBody2D
class_name Hero


@export var _sprite: Sprite2D
@export var _arrow_label: Label

var _current_direction: float = 90.0 # 現在の移動方向 (deg)
var _last_direction: float = 90.0 # 最後に移動した方向 (deg)
@export var _default_arrow_rotation_speed: int = 90 # 移動方向の矢印の回転速度 (deg/s)

var _move_tween: Tween


signal move_started # 移動が開始した
signal move_finished # 移動が終了した


# 移動状態
enum MoveState {
	WAITING, # 入力待ち
	MOVEING, # 移動中
	COOLING, # 移動後のクールタイム
}


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_process_rotate_direction(delta)


# direction の向きに strength の強さで移動する
func move(strength: float) -> void:
	pass


func _process_rotate_direction(delta: float) -> void:
	var speed = _default_arrow_rotation_speed
	_current_direction += speed * delta
	if 360.0 < _current_direction:
		_current_direction -= 360.0

	_arrow_label.rotation_degrees = _current_direction

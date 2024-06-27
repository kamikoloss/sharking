extends RigidBody2D
class_name Hero


signal move_started # 移動が開始した
signal move_finished # 移動が終了した


# 移動状態
enum MoveState {
	WAITING, # 何もしていない/移動タメ開始待ち
	CHARGING, # 移動タメ中/移動タメ終了待ち
	MOVEING, # 移動中/移動終了待ち
	COOLING, # クールタイム中/クールタイム終了待ち
}


var move_state = MoveState.WAITING

@export var _sprite: Sprite2D
@export var _arrow: Control
@export var _arrow_square: TextureRect

var _direction: float = 90.0 # 現在の移動方向 (deg)
@export var _direction_rotation_speed_default: float = 90.0
var _direction_rotation_speed: float = _direction_rotation_speed_default # 移動方向の矢印の回転速度 (deg/s)

var charge: float = 0.0 # 現在の移動タメ度 (最大 1.0)
@export var _charge_speed_default: float = 0.2
var _charge_speed: float = _charge_speed_default  # 移動タメの速度 (/s)
@export var _charge_duration_default: float = 1.0
var _charge_duration = _charge_duration_default # 移動タメが最大に達するまでの秒数 (s)

var _move_tween: Tween:
	get:
		if _move_tween:
			_move_tween.kill()
		_move_tween = create_tween()
		return _move_tween
var _arrow_square_tween: Tween:
	get:
		if _arrow_square_tween:
			_arrow_square_tween.kill()
		_arrow_square_tween = create_tween()
		return _arrow_square_tween


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_process_rotate_direction(delta)


# 移動のタメを開始する
func enter_charge() -> void:
	move_state = MoveState.CHARGING

	_move_tween.set_loops()
	_move_tween.set_parallel(true)
	_move_tween.tween_method(func(v): charge = _charge_speed * v, 0.0, 1.0, _charge_duration)
	_move_tween.tween_property(_arrow_square, "scale.x", 1.0, _charge_duration)


# 移動のタメを終了する
func exit_charge() -> void:
	move_state = MoveState.COOLING

	_move_tween.set_parallel(true)
	_move_tween.set_ease(Tween.EASE_OUT)
	_move_tween.set_trans(Tween.TRANS_QUINT)
	charge = 0.0
	_move_tween.tween_property(_arrow_square, "scale.x", 0.0, _charge_duration / 4)

	move_started.emit()


func _process_rotate_direction(delta: float) -> void:
	if move_state != MoveState.WAITING:
		return

	_direction += _direction_rotation_speed * delta
	if 360.0 < _direction:
		_direction -= 360.0

	_arrow.rotation_degrees = _direction

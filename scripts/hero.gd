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


const MOVE_IMPULSE_BASE = 500 # 移動タメの係数


var move_state = MoveState.WAITING
var charge: float = 0.0 # 現在の移動タメ度 (最大 1.0)


@export var _sprite: Sprite2D
@export var _arrow: Control
@export var _arrow_square: TextureRect
@export var _arrow_square_bg: TextureRect

var _direction: float = 0.0 # 現在の移動方向 (deg)
@export var _direction_rotation_speed_default: float = 90.0 # 移動方向の矢印の回転速度 (deg/s)
var _direction_rotation_speed: float = _direction_rotation_speed_default

@export var _charge_duration_default: float = 3.0 # 移動タメの周期 (s)
var _charge_duration = _charge_duration_default

var _sprite_tween: Tween:
	get:
		if _sprite_tween:
			_sprite_tween.kill()
		_sprite_tween = create_tween()
		return _sprite_tween
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

	# arrow
	_arrow_square_bg.visible = true
	var tween = _arrow_square_tween
	tween.set_loops()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_method(func(v): charge = v, 0.0, 1.0, _charge_duration)
	tween.tween_method(func(v): _arrow_square.scale.y = v, 0.0, 1.0, _charge_duration)


# 移動のタメを終了する
func exit_charge() -> void:
	move_state = MoveState.COOLING

	# 移動する
	var impulse = Vector2.UP.rotated(deg_to_rad(_direction)) * charge * MOVE_IMPULSE_BASE
	print("[Hero] impulse! direction: %s, charge: %s, vector: %s" % [_direction, charge, impulse])
	apply_impulse(impulse)

	# arrow
	_arrow_square_bg.visible = false
	var tween = _arrow_square_tween
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_method(func(v): _arrow_square.scale.y = v, charge, 0.0, 0.25)
	charge = 0.0
	tween.finished.connect(func(): move_state = MoveState.WAITING)

	print("[Hero] move started.")
	move_started.emit()


func _process_rotate_direction(delta: float) -> void:
	if move_state != MoveState.WAITING:
		return

	_direction += _direction_rotation_speed * delta
	if 360.0 < _direction:
		_direction -= 360.0

	_arrow.rotation_degrees = _direction

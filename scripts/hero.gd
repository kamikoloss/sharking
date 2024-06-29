extends Area2D
class_name Hero


signal move_state_changed


# 移動状態
enum MoveState {
	WAITING, # 何もしていない/移動タメ開始待ち
	CHARGING, # 移動タメ中/移動タメ終了待ち
	MOVING, # 移動中/移動終了待ち
	COOLING, # クールタイム中/クールタイム終了待ち
}


const MOVE_VECTOR_RATIO = 500 # 移動距離の係数


var move_state = MoveState.WAITING:
	set(value):
		var from = move_state
		move_state = value
		move_state_changed.emit(value)
		print("[Hero] move state changed. %s -> %s" % [MoveState.keys()[from], MoveState.keys()[value]])

var charge: float = 0.0 # 現在の移動タメ度 (最大 1.0)
var level: int = 0 # 経験値によって増えるレベル


@export var _sprite: Sprite2D
@export var _arrow: Control
@export var _arrow_square: TextureRect
@export var _arrow_square_bg: TextureRect

var _direction: float = 0.0 # 現在の移動方向 (deg)
@export var _direction_rotation_speed_default: float = 90.0 # 移動方向の矢印の回転速度 (deg/s)
var _direction_rotation_speed: float = _direction_rotation_speed_default

@export var _charge_duration_default: float = 3.0 # 移動タメの周期 (s)
var _charge_duration = _charge_duration_default

var _move_tween: Tween:
	get:
		if _move_tween:
			_move_tween.kill()
		_move_tween = create_tween()
		return _move_tween
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
	if move_state != MoveState.WAITING:
		return
	move_state = MoveState.CHARGING
	_enter_arrow() # charge も変わる


# 移動のタメを終了する
func exit_charge() -> void:
	if move_state != MoveState.CHARGING:
		return
	move_state = MoveState.MOVING
	_move()
	_exit_arrow()
	charge = 0.0


func _process_rotate_direction(delta: float) -> void:
	if move_state != MoveState.WAITING:
		return

	# TODO: 反時計回りへの対応
	_direction += _direction_rotation_speed * delta
	if 360.0 < _direction:
		_direction -= 360.0

	_arrow.rotation_degrees = _direction


# 移動する
func _move():
	var tween = _move_tween
	var dest_position = position + Vector2.UP.rotated(deg_to_rad(_direction)) * charge * MOVE_VECTOR_RATIO
	var move_duration = _charge_duration * charge # TODO
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", dest_position, move_duration)
	tween.finished.connect(func(): move_state = MoveState.WAITING)
	print("[Hero] move. direction: %s, charge: %s, dest: %s" % [_direction, charge, dest_position])


func _enter_arrow():
	_arrow_square_bg.visible = true
	var tween = _arrow_square_tween
	tween.set_loops()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_method(func(v): charge = v, 0.0, 1.0, _charge_duration)
	tween.tween_method(func(v): _arrow_square.scale.y = v, 0.0, 1.0, _charge_duration)


func _exit_arrow():
	_arrow_square_bg.visible = false
	var tween = _arrow_square_tween
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_method(func(v): _arrow_square.scale.y = v, charge, 0.0, 0.25)

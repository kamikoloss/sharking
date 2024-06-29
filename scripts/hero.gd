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


const MOVE_VECTOR_RATIO: int = 500 # 移動距離の係数
const MOVE_BEFORE_SEC: float = 0.5 # 移動開始前の秒数


var move_state = MoveState.WAITING:
	set(value):
		var from = move_state
		move_state = value
		move_state_changed.emit(value)
		print("[Hero] move state changed. %s -> %s" % [MoveState.keys()[from], MoveState.keys()[value]])

var charge: float = 0.0 # 現在の移動タメ度 (最大 1.0)
var exp_point: int = 10 # 取得した経験値ポイント


@export var _sprite: Sprite2D
@export var _label_level: Label
@export var _arrow: Control
@export var _arrow_square: TextureRect
@export var _arrow_square_ct: TextureRect # クールタイム用
@export var _arrow_square_bg: TextureRect # 背景用

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
var _arrow_square_tween: Tween:
	get:
		if _arrow_square_tween:
			_arrow_square_tween.kill()
		_arrow_square_tween = create_tween()
		return _arrow_square_tween
var _arrow_square_ct_tween: Tween:
	get:
		if _arrow_square_ct_tween:
			_arrow_square_ct_tween.kill()
		_arrow_square_ct_tween = create_tween()
		return _arrow_square_ct_tween
var _arrow_square_bg_tween: Tween:
	get:
		if _arrow_square_bg_tween:
			_arrow_square_bg_tween.kill()
		_arrow_square_bg_tween = create_tween()
		return _arrow_square_bg_tween


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_label_level.text = str(exp_point)
	
	_arrow_square.scale.y = 0.0
	_arrow_square_ct.scale.y = 0.0
	_arrow_square_bg.scale.y = 0.0


func _process(delta: float) -> void:
	_process_rotate_direction(delta)


# 移動のタメを開始する
func enter_charge() -> void:
	if move_state != MoveState.WAITING:
		return
	move_state = MoveState.CHARGING

	# _arrow_square_bg
	var arrow_square_bg_tween = _arrow_square_bg_tween
	arrow_square_bg_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	arrow_square_bg_tween.tween_method(func(v): _arrow_square_bg.scale.y = v, 0.0, 1.0, 0.25)

	# _arrow_square
	var tween = _arrow_square_tween
	tween.set_loops()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_method(func(v): charge = v, 0.0, 1.0, _charge_duration)
	tween.tween_method(func(v): _arrow_square.scale.y = v, 0.0, 1.0, _charge_duration)


# 移動のタメを終了する
func exit_charge() -> void:
	if move_state != MoveState.CHARGING:
		return
	move_state = MoveState.MOVING

	# _arrow_square_bg
	var arrow_square_bg_tween = _arrow_square_bg_tween
	arrow_square_bg_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	arrow_square_bg_tween.tween_method(func(v): _arrow_square_bg.scale.y = v, 1.0, 0.0, 0.25)

	# _arrow_square
	var arrow_square_tween = _arrow_square_tween
	arrow_square_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	arrow_square_tween.tween_method(func(v): _arrow_square.scale.y = v, charge, 0.0, 0.25)

	# move
	_sprite.flip_h = 180.0 < _direction
	var move_tween = _move_tween

	var _before_duration = MOVE_BEFORE_SEC # TODO: ping を考慮する
	move_tween.set_parallel(true)
	move_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	move_tween.tween_property(_sprite, "rotation_degrees", _direction, _before_duration)
	move_tween.tween_property(_sprite, "scale", Vector2(clampf(charge, 0.6, 0.8), 0.4), _before_duration)

	var dest_position = position + Vector2.UP.rotated(deg_to_rad(_direction)) * charge * MOVE_VECTOR_RATIO
	var move_duration = _charge_duration * charge
	move_tween.chain()
	move_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	move_tween.tween_property(self, "position", dest_position, move_duration)
	move_tween.tween_property(_sprite, "scale", Vector2(0.4, 0.4), 0.5)
	move_tween.finished.connect(func(): move_state = MoveState.WAITING)

	# _arrow_square_ct
	_arrow_square_ct.scale.y = charge
	var arrow_square_ct_tween = _arrow_square_ct_tween
	arrow_square_ct_tween.tween_interval(_before_duration)
	arrow_square_ct_tween.tween_method(func(v): _arrow_square_ct.scale.y = v, charge, 0.0, move_duration)

	# finish
	charge = 0.0
	print("[Hero] move. direction: %s, charge: %s, dest: %s" % [_direction, charge, dest_position])


func _on_area_entered(area: Area2D) -> void:
	if area is Exp:
		exp_point += area.point
		_label_level.text = str(exp_point)


func _process_rotate_direction(delta: float) -> void:
	if move_state != MoveState.WAITING:
		return

	# TODO: 反時計回りへの対応
	_direction += _direction_rotation_speed * delta
	if 360.0 < _direction:
		_direction -= 360.0

	_arrow.rotation_degrees = _direction

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
# Tween
enum TweenType {
	MOVE, # 座標移動
	DIRECTION, # 移動方向の回転速度
	ARROW_SQ, # 矢印の棒 (タメ)
	ARROW_SQ_CT, # 矢印の棒 (クールタイム)
	ARROW_SQ_BG, # 矢印の棒 (タメ背景)
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
@export var _level_label: Label
@export var _arrow: Control # 矢印
@export var _arrow_square: TextureRect # 矢印の棒 (タメ)
@export var _arrow_square_ct: TextureRect # 矢印の棒 (クールタイム)
@export var _arrow_square_bg: TextureRect # 矢印の棒 (タメ背景)

var _direction: float = 0.0 # 現在の移動方向 (deg)
@export var _direction_rotation_speed_default: float = 90.0 # 移動方向の矢印の回転速度 (deg/s)
var _direction_rotation_speed: float = _direction_rotation_speed_default

@export var _charge_duration_default: float = 3.0 # 移動タメの周期 (s)
var _charge_duration = _charge_duration_default

var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_level_label.text = str(exp_point)
	
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

	# DIRECTION
	var tween_direction = _get_tween(TweenType.DIRECTION)
	tween_direction.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_direction.tween_method(func(v): _direction_rotation_speed = v, _direction_rotation_speed_default, 0.0, 0.5)

	# ARROW_SQ_CT
	var tween_arrow_sq_ct = _get_tween(TweenType.ARROW_SQ_CT)
	tween_arrow_sq_ct.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_arrow_sq_ct.tween_method(func(v): _arrow_square_bg.scale.y = v, 0.0, 1.0, 0.25)

	# ARROW_SQ
	var tween_arrow_sq = _get_tween(TweenType.ARROW_SQ)
	tween_arrow_sq.set_loops()
	tween_arrow_sq.set_parallel(true)
	tween_arrow_sq.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween_arrow_sq.tween_method(func(v): charge = v, 0.0, 1.0, _charge_duration)
	tween_arrow_sq.tween_method(func(v): _arrow_square.scale.y = v, 0.0, 1.0, _charge_duration)


# 移動のタメを終了する
func exit_charge() -> void:
	if move_state != MoveState.CHARGING:
		return
	move_state = MoveState.MOVING

	var before_duration = MOVE_BEFORE_SEC # TODO: ping を考慮する
	var dest_position = position + Vector2.UP.rotated(deg_to_rad(_direction)) * charge * MOVE_VECTOR_RATIO
	var move_duration = _charge_duration * charge

	# DIRECTION
	_direction_rotation_speed = 0.0 # ここで止めないと enter_charge() の減速が続いてしまう
	var tween_direction = _get_tween(TweenType.DIRECTION)
	tween_direction.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween_direction.tween_interval(before_duration + move_duration)
	tween_direction.tween_method(func(v): _direction_rotation_speed = v, 0.0, _direction_rotation_speed_default, 0.5)

	# ARROW_SQ_BG
	var tween_arrow_sq_bg = _get_tween(TweenType.ARROW_SQ_BG)
	tween_arrow_sq_bg.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_arrow_sq_bg.tween_method(func(v): _arrow_square_bg.scale.y = v, 1.0, 0.0, 0.25)

	# ARROW_SQ_CT
	_arrow_square_ct.scale.y = charge
	var tween_arrow_sq_ct = _get_tween(TweenType.ARROW_SQ_CT)
	tween_arrow_sq_ct.tween_interval(before_duration)
	tween_arrow_sq_ct.tween_method(func(v): _arrow_square_ct.scale.y = v, charge, 0.0, move_duration)

	# ARROW_SQ
	var tween_arrow_sq = _get_tween(TweenType.ARROW_SQ)
	tween_arrow_sq.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_arrow_sq.tween_method(func(v): _arrow_square.scale.y = v, charge, 0.0, 0.25)

	# MOVE
	_sprite.flip_h = 180.0 < _direction
	var tween_move = _get_tween(TweenType.MOVE)

	tween_move.set_parallel(true)
	tween_move.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_move.tween_property(_sprite, "rotation_degrees", _direction, before_duration)
	tween_move.tween_property(_sprite, "scale", Vector2(clampf(charge, 0.6, 0.8), 0.4), before_duration)

	tween_move.chain()
	tween_move.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_move.tween_property(self, "position", dest_position, move_duration)
	tween_move.tween_property(_sprite, "scale", Vector2(0.4, 0.4), 0.5)
	tween_move.finished.connect(func(): move_state = MoveState.WAITING)

	# finish
	charge = 0.0
	print("[Hero] move. direction: %s, charge: %s, dest: %s" % [_direction, charge, dest_position])


func _on_area_entered(area: Area2D) -> void:
	if area is Exp:
		exp_point += area.point
		_level_label.text = str(exp_point)


func _process_rotate_direction(delta: float) -> void:
	# TODO: 反時計回りへの対応
	_direction += _direction_rotation_speed * delta
	if 360.0 < _direction:
		_direction -= 360.0
	_arrow.rotation_degrees = _direction


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]

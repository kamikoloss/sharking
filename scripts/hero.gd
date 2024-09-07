class_name Hero
extends Area2D


# (charge: タメの強さ, dest_position: 行き先の座標, move_duration: 移動にかかる時間)
signal move_started
# ()
signal move_stopped
# ()
signal damaged


# 移動状態
enum MoveState {
	WAITING, # 何もしていない / (移動タメ開始 or 移動) 待ち
	CHARGING, # 移動タメ中 / 移動タメ終了待ち
	MOVING, # 移動中 / 移動終了待ち
}
# Tween
enum TweenType {
	MOVE, # 座標移動
	DIRECTION, # 移動方向の回転速度
	ARROW_SQ, # 矢印の棒 (タメ)
	ARROW_SQ_CT, # 矢印の棒 (クールタイム)
	ARROW_SQ_BG, # 矢印の棒 (タメ背景)
	DAMAGE, # ダメージ時の色
}


const MOVE_VECTOR_RATIO: int = 500 # 移動距離の係数
const MOVE_BEFORE_SEC: float = 0.5 # 移動開始前の秒数
const DAMAGE_RATIO: float = 0.5 # ダメージの係数

var move_state = MoveState.WAITING:
	set(value):
		var from = move_state
		move_state = value
		print("[Hero %s] move state changed. %s -> %s" % [id, MoveState.keys()[from], MoveState.keys()[value]])

var id: int = -1
var is_client: bool = false # Client 上の Hero かどうか (<--> Server)
var is_local: bool = false # 実行マシン上で操作している Hero かどうか (<--> Remote)
var is_bot: bool = false # bot かどうか

var charge: float = 0.0 # 現在の移動タメ度 (最大 1.0)
var exp_point: int = 0: # 取得した経験値ポイント
	set(value):
		exp_point = value
		_exp_label.text = str(exp_point)
var health_point: int = 100: # 体力ポイント
	set(value):
		health_point = value
		_health_label.text = str(health_point)
var got_exp_ids = [] # 移動中に取得した EXP の ID のリスト, 移動ごとにリセットされる


@export var _camera: Camera2D
@export var _sprite: Sprite2D
@export var _exp_label: Label
@export var _health_label: Label
@export var _arrow: Control # 矢印
@export var _arrow_square: TextureRect # 矢印の棒 (タメ)
@export var _arrow_square_ct: TextureRect # 矢印の棒 (クールタイム)
@export var _arrow_square_bg: TextureRect # 矢印の棒 (タメ背景)

@export var _texture_hero_main: Texture
@export var _texture_hero_other: Texture
@export var _texture_hero_bot: Texture

var _direction: float = 0.0 # 現在の移動方向 (deg)
@export var _direction_rotation_speed_default: float = 90.0 # 移動方向の矢印の回転速度 (deg/s)
var _direction_rotation_speed: float = _direction_rotation_speed_default

@export var _charge_duration_default: float = 3.0 # 移動タメの周期 (s)
var _charge_duration = _charge_duration_default

var _tweens: Dictionary = {} # { TweenType: Tween, ... } 
var _move_start_position: Vector2 # 移動を開始した位置


func _ready() -> void:
	area_entered.connect(_on_area_entered)

	if is_local:
		change_hero_texture(HeroTextureType.Main)
	elif is_bot:
		change_hero_texture(HeroTextureType.Bot)
	else:
		change_hero_texture(HeroTextureType.Other)

	_exp_label.text = str(exp_point)
	_health_label.text = str(health_point)

	if is_local:
		_arrow_square.scale.y = 0.0
		_arrow_square_ct.scale.y = 0.0
		_arrow_square_bg.scale.y = 0.0
	else:
		_camera.enabled = false
		_arrow.visible = false


func _process(delta: float) -> void:
	if is_local:
		_process_rotate_direction(delta)


# 移動のタメを開始する
func enter_charge() -> void:
	# Server/Remote: 何もしない
	if not is_client or not is_local:
		return
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
	# Server/Remote: 何もしない
	if not is_client or not is_local:
		return
	if move_state != MoveState.CHARGING:
		return

	var dest_position = position + Vector2.UP.rotated(deg_to_rad(_direction)) * charge * MOVE_VECTOR_RATIO
	var before_duration = MOVE_BEFORE_SEC
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
	tween_arrow_sq.tween_method(func(v): _arrow_square.scale.y = v, charge, 0.0, 0.5)

	# 移動する
	move(dest_position, before_duration, move_duration)


# 移動する
func move(dest_position: Vector2, before_duration: float, move_duration: float) -> void:
	# Server: 何もしない
	if not is_client:
		return
	if move_state == MoveState.MOVING:
		return

	move_started.emit(charge, dest_position, move_duration)
	move_state = MoveState.MOVING
	_move_start_position = self.position

	var tween_move = _get_tween(TweenType.MOVE)
	var direction = rad_to_deg(position.angle_to_point(dest_position)) + 90.0
	direction = _clamp_deg(direction)

	# 移動先の方向に回転する
	_sprite.flip_h = 180.0 < direction
	tween_move.set_parallel(true)
	tween_move.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_move.tween_property(_sprite, "rotation_degrees", direction, before_duration)
	tween_move.tween_property(_sprite, "scale", Vector2(0.2, 0.2), before_duration) # TODO: 倍率にする
	# 移動先の座標まで移動する
	tween_move.chain()
	tween_move.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_move.tween_property(self, "position", dest_position, move_duration)
	tween_move.tween_property(_sprite, "scale", Vector2(0.15, 0.15), 0.5) # TODO: 倍率にする
	tween_move.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	move_state = MoveState.WAITING
	got_exp_ids = []
	charge = 0.0
	move_stopped.emit()


# ダメージを受ける
func damage(point: int) -> void:
	health_point -= point
	damaged.emit()

	var tween_damage = _get_tween(TweenType.DAMAGE)
	# 死んだとき
	if health_point <= 0:
		tween_damage.set_parallel(true)
		tween_damage.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		tween_damage.tween_property(_sprite, "rotation_degrees", 1440, 3.0)
		tween_damage.tween_property(_sprite, "self_modulate", Color.BLUE, 1.0)
		tween_damage.tween_property(_sprite, "scale", Vector2.ZERO, 3.0)
	# ダメージを受けたとき
	else:
		_sprite.self_modulate = Color.RED
		tween_damage.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		tween_damage.tween_property(_sprite, "self_modulate", Color.WHITE, 1.0)


# Hero の見た目を変更する
enum HeroTextureType { Main, Other, Bot }
func change_hero_texture(type: HeroTextureType) -> void:
	match type:
		HeroTextureType.Main:
			_sprite.texture = _texture_hero_main
		HeroTextureType.Other:
			_sprite.texture = _texture_hero_other
		HeroTextureType.Bot:
			_sprite.texture = _texture_hero_bot


func _on_area_entered(area: Area2D) -> void:
	# Server: 何もしない
	if not is_client:
		return

	# EXP
	if area is Exp:
		exp_point += area.point
		if is_local:
			got_exp_ids.append(area.id)
	# Hero
	if area is Hero:
		# 自分が移動中の場合: (ダメージを与えて) 元の位置に戻る
		if move_state == MoveState.MOVING:
			move_state = MoveState.WAITING # いったん初期状態に戻す
			move(_move_start_position, 0.5, 1.0)
		# 相手が移動中の場合: ダメージを受ける
		if area.move_state == MoveState.MOVING:
			var damege_base = clamp(area.exp_point, 0.0, 100.0)
			var damage_point = damege_base * area.charge * DAMAGE_RATIO
			print("[Hero %s] damaged by hero. %s x %s x %s = %s" % [id, damege_base, area.charge, DAMAGE_RATIO, damage_point])
			damage(damage_point)
	# Wall
	if area.is_in_group("Wall"):
		# ダメージを受ける
		var damage_point = 50
		print("[Hero %s] damaged by wall" % [id])
		damage(damage_point)
		# 死んでない場合: 元の位置に戻る
		if 0 < health_point:
			move_state = MoveState.WAITING # いったん初期状態に戻す
			move(_move_start_position, 0.5, 1.0)


func _process_rotate_direction(delta: float) -> void:
	_direction += _direction_rotation_speed * delta
	_direction = _clamp_deg(_direction)
	_arrow.rotation_degrees = _direction


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]


# 角度を 0-360 に丸める (負の角度にも対応)
func _clamp_deg(deg: float) -> float:
	if deg < 0.0:
		return deg + 360.0
	elif 360.0 < deg:
		return deg - 360.0
	else:
		return deg

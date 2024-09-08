class_name Exp
extends Area2D


var id: int = -1
var point: int = 0


@export var _sprite: Sprite2D
@export var _label: Label

var _die_tween: Tween:
	get:
		if _die_tween:
			_die_tween.kill()
		_die_tween = create_tween()
		return _die_tween
var _move_tween: Tween:
	get:
		if _move_tween:
			_move_tween.kill()
		_move_tween = create_tween()
		return _move_tween


func _init(point: int = 0, position: Vector2 = Vector2.ZERO) -> void:
	self.point = point
	self.position = position


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_init_visual()
	_start_move()


# 自身を破壊する
func destroy() -> void:
	_label.visible = false

	var tween = _die_tween
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_sprite, "self_modulate", Color.WHITE, 0.25)
	tween.tween_property(_sprite, "self_modulate", Color.TRANSPARENT, 1.0)
	tween.finished.connect(func(): queue_free())
	#print("[Exp %s] died." % [id])


func _on_area_entered(area: Area2D) -> void:
	# Hero
	if area is Hero:
		# Client/Local の場合: 破壊する
		if area.is_client and area.is_local:
			destroy()
		# Server の場合: 破壊しない
		# Client から受信したデータを元に Level が手動で破壊する
	# Wall
	if area.is_in_group("Wall"):
		# 流されすぎているので中央付近に戻る
		self.position = Vector2(randf_range(-256, 256), randf_range(-256, 256))
		_start_move()


# 自身の見た目を決定する
func _init_visual() -> void:
	var scale_ratio: = 1.0 + (float(point) - 1.0) / 2.0
	self.scale *= scale_ratio

	if 1 < point:
		_label.text = str(point)
	else:
		_label.visible = false


# 移動を開始する
func _start_move() -> void:
	var dest_position = self.position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	var tween = _move_tween
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "position", dest_position, randf_range(4, 8))
	tween.finished.connect(_start_move) # 座標を相対的に算出するので最初からやり直す

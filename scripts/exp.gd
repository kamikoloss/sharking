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


func _init(point: int = 0, position: Vector2 = Vector2.ZERO) -> void:
	self.point = point
	self.position = position


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_init_visual()


# 自身を (見た目上) 破壊する
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
		# Client の場合: 破壊する
		# Server の場合: 破壊しない (Client から受信したデータを元に Level が手動で破壊する)
		if area.is_client:
			destroy()


# 自身の見た目を決定する
func _init_visual() -> void:
	var scale_ratio: = 1.0 + (float(point) - 1.0) / 2.0
	scale *= scale_ratio

	if 1 < point:
		_label.text = str(point)
	else:
		_label.visible = false

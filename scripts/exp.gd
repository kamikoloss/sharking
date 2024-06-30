class_name Exp
extends Area2D


var is_active: bool = true
var point: int = 0


@export var _sprite: Sprite2D
@export var _label: Label

var _die_tween: Tween:
	get:
		if _die_tween:
			_die_tween.kill()
		_die_tween = create_tween()
		return _die_tween


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_init_visual()


func _on_area_entered(area: Area2D) -> void:
	if area is Hero:
		_die()


# 自身の見た目を決定する
func _init_visual() -> void:
	var scale_ratio: = 1.0 + (float(point) - 1.0) / 2.0
	scale *= scale_ratio

	if 1 < point:
		_label.text = str(point)
	else:
		_label.visible = false


# 消滅する
func _die() -> void:
	is_active = false
	_label.visible = false

	var tween = _die_tween
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_sprite, "self_modulate", Color.WHITE, 0.25)
	tween.tween_property(_sprite, "self_modulate", Color.TRANSPARENT, 1.0)
	tween.finished.connect(func(): queue_free())
	print("[Exp %s] die." % get_instance_id())

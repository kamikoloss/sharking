extends Area2D
class_name Exp


var is_active: bool = true
var point: int = 0


@export var _sprite: Sprite2D
@export var _label: Label

var _kill_tween: Tween:
	get:
		if _kill_tween:
			_kill_tween.kill()
		_kill_tween = create_tween()
		return _kill_tween


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_refresh()


# 消滅する
func kill() -> void:
	is_active = false
	_label.visible = false

	var tween = _kill_tween
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_sprite, "self_modulate", Color.WHITE, 0.1)
	tween.tween_property(_sprite, "self_modulate", Color.TRANSPARENT, 1.0)
	tween.finished.connect(func(): queue_free())
	print("[Exp %s] kill." % get_instance_id())


func _on_area_entered(area: Area2D) -> void:
	if area is Hero:
		kill()


func _refresh() -> void:
	var scale_ratio: = 1.0 + (float(point) - 1.0) / 2.0
	scale *= scale_ratio

	if 1 < point:
		_label.text = str(point)
	else:
		_label.visible = false

extends Area2D
class_name Exp


var point: int = 0


@export var _label: Label


func _ready() -> void:
	var scale_ratio: = 1.0 + (float(point) - 1.0) / 2.0
	scale *= scale_ratio

	if 1 < point:
		_label.text = str(point)
	else:
		_label.visible = false

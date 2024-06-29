extends Area2D
class_name Exp


var point: int = 0


@export var _label: Label


func _ready() -> void:
	_label.text = str(point)
	scale *= point

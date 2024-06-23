#@tool
extends Node2D


func _ready():
	_change_project_settings(true)


func _change_project_settings(is_enable: bool) -> void:
	if is_enable:
		ProjectSettings.set_setting("display/window/size/viewport_width", 1440)
		ProjectSettings.set_setting("display/window/size/viewport_height", 40)
	else:
		ProjectSettings.set_setting("display/window/size/viewport_width", 360)
		ProjectSettings.set_setting("display/window/size/viewport_height", 640)

extends Node2D


@export var _level: Level
@export var _main_hero: Hero

@export var _button_center: Button
@export var _button_left: Button
@export var _button_right: Button


func _ready() -> void:
	_button_center.button_down.connect(_on_center_button_down)
	_button_center.button_up.connect(_on_center_button_up)
	_button_left.button_down.connect(_on_left_button_down)
	_button_right.button_down.connect(_on_right_button_down)


func _on_center_button_down() -> void:
	_main_hero.enter_charge()


func _on_center_button_up() -> void:
	_main_hero.exit_charge()


func _on_left_button_down() -> void:
	_main_hero.change_hero_texture(Hero.HeroTextureType.OTHER)


func _on_right_button_down() -> void:
	_main_hero.change_hero_texture(Hero.HeroTextureType.BOT)

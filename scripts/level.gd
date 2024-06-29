extends Node2D
class_name Level


const CHARACTERS = "0123456789abcdefghijklmnopqrstuvwxyz"
const ID_LENGTH = 16


var exp_intance_ids: Array[int] = []


@export var _exp_scene: PackedScene
@export var _exps_node: Node2D
var _exp_point_sum = 500 # 合計何 pt になるまで EXP を生成するか
var _exp_point_list: Array[int] = [1, 1, 1, 2, 2, 3] # 生成する EXP のポイントのリスト

var _level_size: int = 640 # Level の大きさ (px, 辺/2)
var _rng = RandomNumberGenerator.new()


func _ready() -> void:
	initialize_exp() # TODO: Server が実行して同期する


# 経験値を初期生成する
func initialize_exp() -> void:
	var sum = 0
	while (sum < _exp_point_sum):
		var exp: Exp = _exp_scene.instantiate()
		var point = _exp_point_list.pick_random()
		exp.point = point
		exp.position = _get_random_position()
		_exps_node.add_child(exp)
		sum += point
		exp_intance_ids.append(exp.get_instance_id())


func _get_random_position() -> Vector2:
	var x = _rng.randi_range(_level_size * -1, _level_size)
	var y = _rng.randi_range(_level_size * -1, _level_size)
	return Vector2(x, y)

class_name Level
extends Node2D


signal exp_spawned(spanwed_exps: Array[Exp]) # EXP が生成された
signal exp_despawned(despawned_exps: Array[Exp]) # EXP が破壊された


# Level 上に存在する EXP { Instance ID: EXP, ... }
# 接続した Client に現在の状態を教えるために保持しておく
var exps_on_level: Dictionary = {}


@export var _exp_scene: PackedScene
@export var _exps_parent_node: Node2D
var _exp_point_sum = 0 # Level 上に存在する EXP pt の合計
var _exp_point_sum_max = 500 # 合計何 pt になるまで EXP を生成するか
var _exp_point_list: Array[int] = [1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 5] # 生成する EXP pt のリスト (確率込み)

var _level_size: int = 640 # Level の大きさ (px, 辺/2)
var _rng = RandomNumberGenerator.new()


func _ready() -> void:
	pass


# 上限になるまでの EXP のリストを取得する
func get_exps_to_limit() -> Array[Exp]:
	var exps: Array[Exp] = []
	var point_sum = _exp_point_sum

	while (point_sum < _exp_point_sum_max):
		var point = _exp_point_list.pick_random()
		var _position = _get_random_position()
		var exp_data = Exp.new(point, _position)

		point_sum += point
		exps.append(exp_data)

	return exps


# EXP を生成する
func spawn_exps(exps: Array) -> void:
	var spawned_exps: Array = []

	for exp in exps:
		# EXP が Level 上に存在しない場合: 生成する
		if not exp.id in exps_on_level.keys():
			var exp_instance: Exp = _exp_scene.instantiate()
			# 引数データに ID が設定されていない場合は Instance ID を使用する (Server)
			# 引数データに ID が設定されている場合はそれを使用する (Client) 
			var id = exp_instance.get_instance_id() if exp.id < 0 else exp.id

			exp_instance.id = id
			exp_instance.point = exp.point
			exp_instance.is_active = true
			exp_instance.position = exp.position
			_exps_parent_node.add_child(exp_instance)

			exps_on_level[exp_instance.id] = exp_instance
			_exp_point_sum -= exp.point
			spawned_exps.append(exp)

	if 0 < len(spawned_exps):
		exp_spawned.emit(spawned_exps)


# EXP を破壊する
func despawn_exps(exps: Array) -> void:
	var despwned_exps: Array = []

	for exp in exps:
		# EXP が Level 上に存在する かつ Level 上に存在する EXP が有効な場合: 破壊する
		if exp.id in exps_on_level.keys() and exps_on_level[exp.id].is_active:
			exps_on_level[exp.id].destroy()

			exps_on_level.erase(exp.id)
			_exp_point_sum -= exp.point
			despwned_exps.append(exp)

	if 0 < len(despwned_exps):
		exp_despawned.emit(despwned_exps)


# 指定範囲内のランダムな座標を取得する
func _get_random_position() -> Vector2:
	var x = _rng.randi_range(_level_size * -1, _level_size)
	var y = _rng.randi_range(_level_size * -1, _level_size)
	return Vector2(x, y)

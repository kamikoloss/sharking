class_name Level
extends Node2D


# Client 上の Level かどうか
var is_client: bool = false

# Level 上に存在する EXP/Hero { ID: Instance, ... }
# Server: 接続した Client に現在の状態を教えるために保持しておく
# Client: 指定 ID の Instance を破壊するために保持しておく
var exps_on_level: Dictionary = {}
var heros_on_level: Dictionary = {}


# EXP
@export var _exp_scene: PackedScene
@export var _exps_parent_node: Node2D
var _exp_point_sum = 0 # Level 上に存在する EXP pt の合計
var _exp_point_sum_max = 1000 # 合計何 pt になるまで EXP を生成するか
var _exp_point_list: Array[int] = [1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 5] # 生成する EXP pt のリスト (確率込み)

# Hero
@export var _hero_scene: PackedScene
@export var _heros_parent_node: Node2D

var _level_size: int = 800 # Level の大きさ (px, 辺/2)


func _ready() -> void:
	pass


# EXP を上限まで生成する (Server 用)
func spawn_exps_to_limit() -> Array[Exp]:
	if is_client:
		return []

	var exps: Array[Exp] = []

	while (_exp_point_sum < _exp_point_sum_max):
		var random_point = _exp_point_list.pick_random()
		var random_position = _get_random_position()
		var exp = Exp.new(random_point, random_position)
		spawn_exp(-1, random_point, random_position)
		exps.append(exp)

	return exps

func _get_random_position() -> Vector2:
	var x = randi_range(_level_size * -1, _level_size)
	var y = randi_range(_level_size * -1, _level_size)
	return Vector2(x, y)


# EXP を生成する
func spawn_exp(id: int, point: int, position: Vector2) -> void:
	if _is_valid_exp(id):
		return

	# EXP インスタンスを生成する
	var exp_instance: Exp = _exp_scene.instantiate()
	# ID が指定されていない場合 Instance ID を使用する (Server)
	# ID が指定されている場合: それを使用する (Client) 
	var exp_id = exp_instance.get_instance_id() if id < 0 else id
	exp_instance.id = exp_id
	exp_instance.point = point
	exp_instance.position = position

	if not is_client:
		_exp_point_sum += point

	_exps_parent_node.add_child(exp_instance)
	exps_on_level[exp_instance.id] = exp_instance

	if not is_client:
		print("(Level/spawn_exp) point sum: %s" % [_exp_point_sum])
		pass


# EXP を破壊する
func despawn_exp(id: int) -> void:
	if not _is_valid_exp(id):
		return

	if not is_client:
		_exp_point_sum -= exps_on_level[id].point

	exps_on_level[id].destroy()
	exps_on_level.erase(id)

	if not is_client:
		print("(Level/despawn_exp) point sum: %s" % [_exp_point_sum])


# Hero を生成する
func spawn_hero(pid: int) -> void:
	# Hero インスタンスを生成する
	var hero_instance = _hero_scene.instantiate()
	hero_instance.id = pid
	hero_instance.is_client = is_client
	hero_instance.is_local = false # Local Hero は Client の _spawn_hero で生成する
	hero_instance.exp_point = 0

	_heros_parent_node.add_child(hero_instance)
	heros_on_level[pid] = hero_instance


# Hero を破壊する
func despawn_hero(pid: int) -> void:
	if not _is_valid_hero(pid):
		return

	heros_on_level[pid].die()
	heros_on_level.erase(pid)


# Hero の情報を更新する
func update_hero(pid: int, exp: int, health: int, pos: Vector2) -> void:
	if not _is_valid_hero(pid):
		return

	heros_on_level[pid].exp_point = exp
	heros_on_level[pid].health_point = health
	heros_on_level[pid].position = pos


# Hero を移動させる
func move_hero(pid: int, charge: float, dest: Vector2, duration: float) -> void:
	if not _is_valid_hero(pid):
		return

	heros_on_level[pid].charge = charge
	heros_on_level[pid].move(dest, 0.5, duration)


func _is_valid_exp(id: int) -> bool:
	return exps_on_level.has(id) and exps_on_level[id] != null


func _is_valid_hero(pid: int) -> bool:
	return heros_on_level.has(pid) and heros_on_level[pid] != null

class_name Level
extends Node2D


# Client 上の Level かどうか
@export var is_client: bool = true

# Level 上に存在する EXP/Hero { ID: Instance, ... }
# Server: 接続した Client に現在の状態を教えるために保持しておく
# Client: 指定 ID の Instance を破壊するために保持しておく
var exps_on_level: Dictionary = {}
var heros_on_level: Dictionary = {}


# EXP
@export var _exp_scene: PackedScene
@export var _exps_parent_node: Node2D
var _exp_point_sum = 0 # Level 上に存在する EXP pt の合計
var _exp_point_sum_max = 500 # 合計何 pt になるまで EXP を生成するか
var _exp_point_list: Array[int] = [1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 5] # 生成する EXP pt のリスト (確率込み)

# Hero
@export var _hero_scene: PackedScene
@export var _heros_parent_node: Node2D

var _level_size: int = 640 # Level の大きさ (px, 辺/2)
var _rng = RandomNumberGenerator.new()


func _ready() -> void:
	pass


# EXP を上限いっぱいまで再生成する (Server 用)
func respawn_exps_to_limit() -> Array[Exp]:
	if is_client:
		return []

	var exps: Array[Exp] = []

	while (_exp_point_sum < _exp_point_sum_max):
		var random_point = _exp_point_list.pick_random()
		var random_position = _get_random_position()
		var exp = Exp.new(random_point, random_position)
		_exp_point_sum += random_point
		spawn_exp(-1, exp.point, exp.position)
		exps.append(exp)

	return exps


# EXP を生成する
func spawn_exp(id: int, point: int, pos: Vector2) -> void:
	# Level 上に存在する場合: 何もしない
	if exps_on_level.has(id):
		return

	# EXP インスタンスを作成する
	var exp_instance: Exp = _exp_scene.instantiate()
	# ID が指定されていない場合 Instance ID を使用する (Server)
	# ID が指定されている場合: それを使用する (Client) 
	var exp_id = exp_instance.get_instance_id() if id < 0 else id
	exp_instance.id = exp_id
	exp_instance.point = point
	exp_instance.position = pos

	_exp_point_sum += point
	_exps_parent_node.add_child(exp_instance)
	exps_on_level[exp_instance.id] = exp_instance

	if not is_client:
		print("(Level/spawn_exp) _exp_point_sum: %s" % [_exp_point_sum])


# EXP を破壊する
func despawn_exp(id: int) -> void:
	# Level 上に存在しない場合: 何もしない
	if not exps_on_level.has(id):
		return

	_exp_point_sum -= exps_on_level[id].point
	exps_on_level[id].destroy()
	exps_on_level.erase(id)

	if not is_client:
		print("(Level/despawn_exp) _exp_point_sum: %s" % [_exp_point_sum])


# Hero を生成する
func spawn_hero(pid: int) -> void:
	# Hero インスタンスを作成する
	var hero_instance = _hero_scene.instantiate()
	hero_instance.id = pid
	hero_instance.is_client = is_client
	hero_instance.exp_point = 0

	_heros_parent_node.add_child(hero_instance)
	heros_on_level[pid] = hero_instance


# Hero を破壊する
func despawn_hero(pid: int) -> void:
	# Level 上に存在しない場合: 何もしない
	if not heros_on_level.has(pid):
		return

	heros_on_level[pid].queue_free()
	heros_on_level.erase(pid)


# Hero の情報を更新する
func update_hero(pid: int, exp: int, pos: Vector2) -> void:
	# Level 上に存在しない場合: 何もしない
	if not heros_on_level.has(pid):
		return

	heros_on_level[pid].exp_point = exp
	heros_on_level[pid].position = pos


# Level 内のランダムな座標を取得する
func _get_random_position() -> Vector2:
	var x = _rng.randi_range(_level_size * -1, _level_size)
	var y = _rng.randi_range(_level_size * -1, _level_size)
	return Vector2(x, y)

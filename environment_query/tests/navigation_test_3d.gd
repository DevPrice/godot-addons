class_name NavigationTest3D extends QueryTest

@export var optimize_path := false
@export var target_distance := 0.5
@export_flags_3d_navigation var navigation_layers := 1

func test_point(context: Node, point: Vector3) -> float:
	if context is not Node3D: return INF
	var map := _get_map(context)
	var path := NavigationServer3D.map_get_path(map, context.global_position, point, optimize_path, navigation_layers)
	if _is_target_reachable(point, path):
		return _get_path_distance(context.global_position, path)
	return INF

func _get_map(node: Node3D) -> RID:
	return node.get_world_3d().navigation_map

func _is_target_reachable(target: Vector3, path: PackedVector3Array) -> bool:
	return path.size() > 0 and path[path.size() - 1].distance_squared_to(target) <= target_distance * target_distance

func _get_path_distance(origin: Vector3, path: PackedVector3Array) -> float:
	var distance: float = 0.0
	var current := origin
	for point: Vector3 in path:
		distance += current.distance_to(point)
		current = point
	return distance

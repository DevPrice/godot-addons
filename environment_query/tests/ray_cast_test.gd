class_name RayCastTest extends QueryTest

@export_flags_3d_physics var mask: int = 1
@export var from_offset := Vector3.ZERO
@export var to_offset := Vector3.ZERO

func test_point(context: Node, point: Vector3) -> float:
	var result := _ray_cast(context, point)
	return 1.0 if result.is_empty() else -1.0

func test_node(context: Node, node: Node) -> float:
	if node is not Node3D: return 1.0
	var result := _ray_cast(context, node.global_position)
	return 1.0 if result.is_empty() or result.get("collider") == node else -1.0

func _ray_cast(context: Node, point: Vector3) -> Dictionary:
	if context is not Node3D: return {"fail": true}
	var world: World3D = context.get_world_3d()
	if not world: return {"fail": true}
	var ray_params := PhysicsRayQueryParameters3D.create(context.global_position + from_offset, point + to_offset, mask)
	return world.direct_space_state.intersect_ray(ray_params)

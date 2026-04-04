class_name DistanceTest extends QueryTest

func test_point(context: Node, point: Vector3) -> float:
	if context is Node3D:
		return context.global_position.distance_to(point)
	return 0.0

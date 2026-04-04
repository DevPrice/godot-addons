class_name PointCircle extends PointGenerator

@export var num_points: int = 8
@export var radius: float = 1.0
@export var offset := Vector3.ZERO

func generate_points(context: Node) -> PackedVector3Array:
	var context_position: Vector3 = context.global_position if context is Node3D else Vector3.ZERO
	var origin := context_position + offset
	var points := PackedVector3Array()
	points.resize(num_points)
	for i: int in num_points:
		var angle := TAU * i / num_points
		points[i] = origin + Vector3(radius * cos(angle), 0.0, radius * sin(angle))
	return points

class_name QueryTest extends Resource

@export var context: QueryContext
@export var score_factor: float = 1.0
@export var filter: QueryTestFilter

func test_point(_context: Node, _point: Vector3) -> float:
	return -1.0

func test_node(context: Node, node: Node) -> float:
	if node is Node3D:
		return test_point(context, node.global_position)
	return -1.0

enum Mode {
	SCORE,
	FILTER,
}

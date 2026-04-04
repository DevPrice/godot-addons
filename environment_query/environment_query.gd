class_name EnvironmentQuery

static func best_point(query: PointQuery3D, source: Node, target: Node = null) -> PackedVector3Array:
	var generator_context := query.point_generator.context.get_context(source, target)
	var points := query.point_generator.generate_points(generator_context)
	var scored_points: Dictionary[Vector3, float] = {}
	for point: Vector3 in points:
		scored_points[point] = 0.0
	for test: QueryTest in query.tests:
		var test_context := test.context.get_context(source, target)
		for point: Vector3 in points:
			if not scored_points.has(point): continue
			var test_result := test.test_point(test_context, point)
			if not is_zero_approx(test.score_factor):
				scored_points[point] += test_result * test.score_factor
			if test.filter and not test.filter.passes(test_result):
				scored_points.erase(point)
	var max_point := _max_point(scored_points)
	#_draw_debug_points(source, points, scored_points, max_point)
	if scored_points.is_empty():
		return PackedVector3Array()
	return PackedVector3Array([max_point])

static func _max_point(values: Dictionary[Vector3, float]) -> Vector3:
	var max_score := -INF
	var max_value := Vector3.ZERO
	for point: Vector3 in values.keys():
		var score := values[point]
		if score > max_score:
			max_score = score
			max_value = point
	return max_value

static func _draw_debug_points(source: Node, points: PackedVector3Array, scored_points: Dictionary[Vector3, float], max_point: Vector3) -> void:
	var debug_root := Node3D.new()
	debug_root.top_level = true
	source.add_child(debug_root)
	var sphere := SphereMesh.new()
	sphere.radius = .0675
	sphere.height = sphere.radius * 2.0
	var filtered_material := StandardMaterial3D.new()
	filtered_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	filtered_material.albedo_color = Color.RED
	var best_material := StandardMaterial3D.new()
	best_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	best_material.albedo_color = Color.GREEN
	var point_material := StandardMaterial3D.new()
	point_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	point_material.albedo_color = Color.BLUE
	for point: Vector3 in points:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = sphere
		mesh_instance.position = point
		if not scored_points.has(point):
			mesh_instance.set_surface_override_material(0, filtered_material)
		elif point == max_point:
			mesh_instance.set_surface_override_material(0, best_material)
		else:
			mesh_instance.set_surface_override_material(0, point_material)
		debug_root.add_child(mesh_instance)
	var timer := source.get_tree().create_timer(5.0, true, true, true)
	timer.timeout.connect(debug_root.queue_free, ConnectFlags.CONNECT_ONE_SHOT)

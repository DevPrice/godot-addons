class_name Nodes

static func find_children_of_type(node: Node, type: Variant, include_internal: bool = false) -> Array[Node]:
	var children: Array[Node] = []
	for i: int in node.get_child_count(include_internal):
		var child := node.get_child(i, include_internal)
		if is_instance_of(child, type):
			children.push_back(child)
	return children

static func find_child_of_type(node: Node, type: Variant, include_internal: bool = false) -> Node:
	for i: int in node.get_child_count(include_internal):
		var child := node.get_child(i, include_internal)
		if is_instance_of(child, type):
			return child
	return null

static func find_ancestor_of_type(node: Node, type: Variant) -> Node:
	var current := node
	while current:
		if is_instance_of(current, type): return current
		current = current.get_parent()
	return null

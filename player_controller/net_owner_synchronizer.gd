extends MultiplayerSynchronizer

func _init() -> void:
	add_visibility_filter(_is_visible_for)

func _is_visible_for(id: int) -> bool:
	var root := get_node_or_null(root_path)
	return root.get("net_owner") == id

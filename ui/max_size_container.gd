@tool class_name MaxSizeContainer extends Container

@export var max_size: Vector2

func _notification(what: int):
	if what == NOTIFICATION_SORT_CHILDREN:
		var fit_size := max_size.min(size) if max_size else size
		var offset := ((size - fit_size) / 2.0).floor()
		for c: Node in get_children():
			if c is Control:
				fit_child_in_rect(c, Rect2(offset, fit_size))

func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2.ZERO
	for c: Node in get_children():
		if c is Control:
			minimum_size = minimum_size.max(c.get_combined_minimum_size())
	return minimum_size.min(max_size) if max_size else minimum_size

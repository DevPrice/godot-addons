class_name Arrays extends Node

static func sample(array: Array, count: int) -> Array:
	var remaining := array.size()
	if count >= remaining:
		return array.duplicate()
	var result: Array = []
	var needed := count
	for item: Variant in array:
		var probability := float(needed) / remaining
		if randf() <= probability:
			needed -= 1
			result.push_back(item)
		remaining -= 1
		if remaining < 1: break
	return result

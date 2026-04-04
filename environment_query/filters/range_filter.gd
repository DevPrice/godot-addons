class_name RangeFilter extends QueryTestFilter

@export var min_value: float = 0.0
@export var max_value: float = 1.0

func passes(value: float) -> bool:
	return value <= max_value and value >= min_value

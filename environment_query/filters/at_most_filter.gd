class_name AtMostFilter extends QueryTestFilter

@export var max_value: float = 0.0

func passes(value: float) -> bool:
	return value <= max_value

class_name AtLeastFilter extends QueryTestFilter

@export var min_value: float = 0.0

func passes(value: float) -> bool:
	return value >= min_value

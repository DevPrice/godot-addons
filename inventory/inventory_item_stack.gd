class_name ItemStack extends Node

signal count_changed(new_count: int)

@export var definition: ItemDefinition
@export var stack_count: int = 1:
	set(value):
		stack_count = value
		count_changed.emit(value)

var _definition_path: String:
	get: return definition.resource_path
	set(value): definition = load(value)

func _ready() -> void:
	if definition:
		for fragment: ItemFragment in definition.fragments:
			fragment.stack_created(self)

func consume(count: int = 1) -> int:
	if count >= stack_count:
		var consumed := stack_count
		stack_count = 0
		if stack_count <= 0:
			queue_free()
		return consumed
	stack_count -= count
	if stack_count <= 0:
		queue_free()
	return count

func consume_all() -> int:
	return consume(stack_count)

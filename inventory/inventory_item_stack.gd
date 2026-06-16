class_name ItemStack extends Node

@export var definition: ItemDefinition
@export var stack_count: int = 1

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

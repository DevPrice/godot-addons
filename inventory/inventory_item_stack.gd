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

class_name Inventory extends Node

var _item_stacks: Array[ItemStack] = []

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED: _refresh_item_stacks()

func _refresh_item_stacks() -> void:
	_item_stacks.clear()
	for child: Node in get_children():
		if child and child is ItemStack:
			_item_stacks.push_back(child)

func get_item_stacks() -> Array[ItemStack]:
	return _item_stacks.duplicate()

func consume(item_definition: ItemDefinition, count: int = 1) -> void:
	for stack: ItemStack in get_item_stacks():
		if stack and stack.definition == item_definition:
			if stack.stack_count > count:
				stack.stack_count -= count
				return
			count -= stack.stack_count
			stack.free()
			if count <= 0:
				return

func consume_all(item_definition: ItemDefinition) -> void:
	for stack: ItemStack in get_item_stacks():
		if stack and stack.definition == item_definition:
			stack.free()

func get_count(item_definition: ItemDefinition) -> int:
	var total_count: int = 0
	for stack: ItemStack in get_item_stacks():
		if stack.definition == item_definition:
			total_count += stack.stack_count
	return total_count

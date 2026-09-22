class_name Inventory extends Node

signal stacks_changed

var _item_stacks: Array[ItemStack] = []

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED: _refresh_item_stacks()

func _refresh_item_stacks() -> void:
	_item_stacks.clear()
	for child: Node in get_children():
		if not child: continue
		if child is ItemStack:
			_item_stacks.push_back(child)
			if not child.count_changed.is_connected(stacks_changed.emit):
				child.count_changed.connect(stacks_changed.emit.unbind(1))
	stacks_changed.emit()

func get_item_stacks() -> Array[ItemStack]:
	return _item_stacks.duplicate()

func add_item(item_definition: ItemDefinition, count: int = 1) -> void:
	for stack: ItemStack in get_item_stacks():
		if stack and stack.definition == item_definition:
			stack.stack_count += count
			stacks_changed.emit()
			return
	var stack := ItemStack.new()
	stack.definition = item_definition
	stack.stack_count = count
	add_child(stack)

func consume(item_definition: ItemDefinition, count: int = 1) -> void:
	for stack: ItemStack in get_item_stacks():
		if stack and stack.definition == item_definition:
			count -= stack.consume(count)
			if count <= 0:
				break
	stacks_changed.emit()

func consume_all(item_definition: ItemDefinition) -> void:
	for stack: ItemStack in get_item_stacks():
		if stack and stack.definition == item_definition:
			stack.free()
	stacks_changed.emit()

func clear() -> void:
	for stack: ItemStack in get_item_stacks():
		stack.queue_free()
	stacks_changed.emit()

func get_count(item_definition: ItemDefinition) -> int:
	var total_count: int = 0
	for stack: ItemStack in get_item_stacks():
		if stack.definition == item_definition:
			total_count += stack.stack_count
	return total_count

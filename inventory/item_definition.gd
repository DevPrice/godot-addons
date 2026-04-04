class_name ItemDefinition extends Resource

@export var fragments: Array[ItemFragment] = []

func create_stack(count: int = 1) -> ItemStack:
	var item_stack := ItemStack.new()
	item_stack.definition = self
	item_stack.stack_count = count
	return item_stack

func find_fragments_of_type(type: Variant) -> Array[ItemFragment]:
	var fragments: Array[ItemFragment] = []
	for fragment: ItemFragment in fragments:
		if is_instance_of(fragment, type):
			fragments.push_back(fragment)
	return fragments

func find_fragment_of_type(type: Variant) -> ItemFragment:
	for fragment: ItemFragment in fragments:
		if is_instance_of(fragment, type):
			return fragment
	return null

class_name AbilityEvent extends RefCounted

var channel: String
var target: Node
var target_tags := GameplayTagContainer.new()
var magnitude: float = 0.0
var data: Variant

func apply(target: Node) -> void:
	if target:
		target.propagate_call("_ability_event", [self])

static func create(
	channel: String,
	target: Node = null,
	magnitude: float = 0.0,
	data: Variant = null,
) -> AbilityEvent:
	var message := AbilityEvent.new()
	message.channel = channel
	message.target = target
	message.magnitude = magnitude
	message.data = data
	var target_actor := GameplayActor.find_actor_for_node(target)
	if target_actor:
		message.target_tags.add_tags(target_actor.get_granted_tags())
		message.target_tags.append(target_actor.get_loose_tags())
	return message

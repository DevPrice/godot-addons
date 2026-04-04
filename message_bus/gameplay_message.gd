class_name GameplayMessage extends RefCounted

var channel: String
var instigator: Node
var target: Node
var instigator_tags := GameplayTagContainer.new()
var target_tags := GameplayTagContainer.new()
var magnitude: float = 0.0
var data: Variant

static func create(
	channel: String,
	instigator: Node = null,
	target: Node = null,
	magnitude: float = 0.0,
) -> GameplayMessage:
	var message := GameplayMessage.new()
	message.channel = channel
	message.instigator = instigator
	message.target = target
	message.magnitude = magnitude
	var instigator_actor := GameplayActor.find_actor_for_node(instigator)
	var target_actor := GameplayActor.find_actor_for_node(target)
	if instigator_actor:
		message.instigator_tags.add_tags(instigator_actor.get_granted_tags())
		message.instigator_tags.append(instigator_actor.get_loose_tags())
	if target_actor:
		message.target_tags.add_tags(target_actor.get_granted_tags())
		message.target_tags.append(target_actor.get_loose_tags())
	return message

class_name Ability extends Node

signal activated

@export var activation_required_tags := PackedStringArray()

func _ready() -> void:
	var actor := get_gameplay_actor()
	if actor: _granted(actor)

func _granted(actor: GameplayActor) -> void:
	pass

func can_activate() -> bool:
	var actor := get_gameplay_actor()
	for required_tag: String in activation_required_tags:
		if not actor or not actor.has_tag(required_tag): return false
	return true

func try_activate() -> bool:
	if can_activate():
		_activate()
		_fx()
		activated.emit()
		return true
	return false

@rpc("any_peer", "call_local", "reliable")
func _activate() -> void:
	pass

func _ability_event(event: AbilityEvent) -> void:
	pass

func _fx() -> void:
	for audio in find_children("*", "AudioStreamPlayer", false):
		audio.play()

func get_controller() -> Controller:
	return Controller.get_instigator(self)

func get_gameplay_actor() -> GameplayActor:
	return GameplayActor.find_actor_for_node(get_parent())

func get_avatar() -> Node:
	var actor := get_gameplay_actor()
	return actor.avatar if actor else null

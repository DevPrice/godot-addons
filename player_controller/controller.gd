class_name Controller extends Node

const DEFAULT_NET_OWNER := -1
const INSTIGATOR_META := &"instigator"
const NOTIFICATION_POSSESSED := -10000
const NOTIFICATION_UNPOSSESSED := -10001

signal avatar_changed(avatar: Node)

var net_owner: int = DEFAULT_NET_OWNER:
	get: return get_multiplayer_authority() if net_owner == DEFAULT_NET_OWNER else net_owner

@export var avatar: Node:
	get: return get_node_or_null(avatar_path)
	set(value):
		avatar_path = get_path_to(value) if value else NodePath()

var avatar_path: NodePath:
	set(value):
		if value != avatar_path:
			avatar_path = value
			avatar_changed.emit(avatar)

func _ready() -> void:
	for child: Node in get_children():
		claim(child)
	child_entered_tree.connect(_on_child_entered)

func _on_child_entered(child: Node) -> void:
	claim(child)

func is_locally_owned() -> bool:
	return multiplayer.get_unique_id() == net_owner

func is_remote_sender() -> bool:
	return multiplayer.get_remote_sender_id() == net_owner

func is_input_source(input_event: InputEvent) -> bool:
	# TODO: Make this robust
	var window := get_window()
	return ((window and window.has_focus()) or input_event is InputEventMouse) and is_locally_owned()

func claim(node: Node, recursive: bool = true) -> void:
	if recursive:
		node.propagate_call("set_meta", [INSTIGATOR_META, self])
		node.propagate_notification(NOTIFICATION_POSSESSED)
	elif not node.has_meta(INSTIGATOR_META) or node.get_meta(INSTIGATOR_META) != self:
		node.set_meta(INSTIGATOR_META, self)
		node.notification(NOTIFICATION_POSSESSED)

func is_instigator(node: Node) -> bool:
	return self == get_instigator(node)

static func get_instigator(node: Node) -> Controller:
	if node and node.has_meta(INSTIGATOR_META):
		var instigator := node.get_meta(INSTIGATOR_META)
		if instigator and instigator is Controller and instigator.is_inside_tree():
			return instigator
	return null

static func clear_instigator(node: Node, recursive: bool = true) -> void:
	if recursive:
		node.propagate_call("remove_meta", [INSTIGATOR_META])
		node.propagate_notification(NOTIFICATION_UNPOSSESSED)
	elif node.has_meta(INSTIGATOR_META):
		node.remove_meta(INSTIGATOR_META)
		node.notification(NOTIFICATION_UNPOSSESSED)

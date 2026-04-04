class_name LocalPlayer extends Player

@export var hud: Control

const LOCAL_PLAYER_META := &"local_player"

func _enter_tree() -> void:
	var viewport := get_viewport()
	if viewport.has_meta(LOCAL_PLAYER_META):
		printerr("LocalPlayer should be unique per viewport")
	viewport.set_meta(LOCAL_PLAYER_META, self)

func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport.has_meta(LOCAL_PLAYER_META):
		viewport.remove_meta(LOCAL_PLAYER_META)

func get_peer_id() -> int:
	return multiplayer.get_unique_id()

static func for_viewport(viewport: Viewport) -> LocalPlayer:
	if viewport.has_meta(LOCAL_PLAYER_META):
		var meta_value := viewport.get_meta(LOCAL_PLAYER_META)
		if meta_value and meta_value is LocalPlayer:
			return meta_value
	return null

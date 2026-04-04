class_name RemotePlayer extends Player

var peer_id: int

func get_peer_id() -> int:
	return peer_id

func _exit_tree() -> void:
	if multiplayer.get_peers().has(peer_id):
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)

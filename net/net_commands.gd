class_name NetCommands extends ConsoleCommands

func _context() -> Dictionary[String, Variant]:
	return {
		"_PEER_ID": multiplayer.get_unique_id(),
	}

func listen(port: int = Net.DEFAULT_PORT) -> void:
	Net.host_server(port)

func join(address: String) -> void:
	Net.join_server(address)

func leave() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func kick(peer_id: int, force: bool = false) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(peer_id, force)

func peers() -> PackedInt32Array:
	return multiplayer.get_peers()

extends Node

const DEFAULT_PORT: int = 13337

signal peer_connected(id: int)

func _ready() -> void:
	_setup_peer()

func _enter_tree() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected, ConnectFlags.CONNECT_DEFERRED)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected, ConnectFlags.CONNECT_DEFERRED)

func _exit_tree() -> void:
	multiplayer.peer_connected.disconnect(_on_peer_connected)
	multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)

func _setup_peer() -> void:
	var args := Args.get_cmd_args()
	var arg_connect = args.get("connect")
	if arg_connect is String:
		join_server(arg_connect)
		return

	var arg_listen = args.get("listen")
	if arg_listen:
		if arg_listen is String:
			if arg_listen.is_valid_int():
				var port := int(arg_listen)
				host_server(port)
				return
			else:
				printerr("Invalid port: %s" % arg_listen)
		host_server()
	else:
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func host_server(port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	print("Hosting on port %s..." % port)
	var error := peer.create_server(port)
	if error:
		printerr("[%s] Failed to create server!" % [error])
		return
	multiplayer.multiplayer_peer = peer

func join_server(address: String) -> void:
	print("Connecting to '%s'..." % address)
	var parsed_url := Url.parse(address)
	var host: String = parsed_url.host
	var port: int = parsed_url.get("port", 13337)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(host, port)
	if error:
		printerr("[%s] Failed to create server!" % [error])
		get_tree().quit.call_deferred(error)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.multiplayer_peer = peer

func _connected_to_server() -> void:
	var unique_id := multiplayer.get_unique_id()
	print("[%s] Connected to server!" % [unique_id])
	if OS.has_feature("debug"): get_window().title = "%s (%s)" % [get_window().title, unique_id]
	multiplayer.get_peers()

func _connection_failed() -> void:
	get_tree().quit.call_deferred(ERR_CANT_CONNECT)

func _on_peer_connected(id: int):
	print("[%s] %s connected!" % [multiplayer.get_unique_id(), id])

func _on_peer_disconnected(id: int):
	print("[%s] %s disconnected!" % [multiplayer.get_unique_id(), id])

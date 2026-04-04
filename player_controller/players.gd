extends Node

@export var player_spawner: MultiplayerSpawner
var _player_scene: PackedScene

var primary_player: LocalPlayer

var _remote_players: Dictionary[int, RemotePlayer] = {}

signal player_joined(controller: PlayerController)
signal player_leaving(controller: PlayerController)

func _enter_tree() -> void:
	var window := get_window()
	if window and window.can_draw():
		primary_player = LocalPlayer.new()
		primary_player.add_to_group("local_players")
		window.add_child.call_deferred(primary_player)

func _exit_tree() -> void:
	primary_player = null

func _ready() -> void:
	if player_spawner: player_spawner.spawn_function = _spawn_controller
	var player_scene_path: String = ProjectSettings.get_setting("players/config/player_controller_scene", "uid://cosl2gcdqfe0x")
	if player_scene_path: _player_scene = load(player_scene_path)

func create_local_player(viewport: Viewport) -> LocalPlayer:
	if not viewport:
		push_error("LocalPlayer must have a viewport!")
		return null
	var player := LocalPlayer.new()
	viewport.add_child(player)
	player.add_to_group("local_players")
	return player

func create_remote_player(peer_id: int) -> RemotePlayer:
	var remote_player := RemotePlayer.new()
	remote_player.peer_id = peer_id
	add_child(remote_player)
	remote_player.add_to_group("remote_players")
	_remote_players[peer_id] = remote_player
	remote_player.tree_exiting.connect(func (): _remote_players.erase(peer_id), ConnectFlags.CONNECT_ONE_SHOT)
	return remote_player

func get_local_players() -> Array[LocalPlayer]:
	var local_players: Array[LocalPlayer] = []
	local_players.append_array(get_tree().get_nodes_in_group("local_players"))
	return local_players

func get_remote_players() -> Array[RemotePlayer]:
	var remote_players: Array[RemotePlayer] = []
	remote_players.append_array(get_tree().get_nodes_in_group("remote_players"))
	return remote_players

func get_players() -> Array[Player]:
	var players: Array[Player] = []
	players.append_array(get_tree().get_nodes_in_group("local_players"))
	players.append_array(get_tree().get_nodes_in_group("remote_players"))
	return players

func get_remote_player(peer_id: int) -> RemotePlayer:
	return _remote_players.get(peer_id)

func join_player(player: Player) -> PlayerController:
	if not player or not player.is_inside_tree():
		printerr("Attempted to join a player not in the tree!")
		return null
	if not is_multiplayer_authority():
		printerr("Only the multiplayer authority can join players!")
		return null
	if not player_spawner:
		push_warning("No player spawner, player will only exist locally.")
		var controller: Controller = _spawn_controller(player.get_peer_id())
		controller.player = player
		controller.claim(player)
		add_child(controller)
		return controller
	var controller: Controller = player_spawner.spawn(player.get_peer_id())
	controller.player = player
	controller.claim(player)
	return controller

func _player_exiting(player_controller: PlayerController) -> void:
	player_leaving.emit(player_controller)

func get_primary_controller() -> PlayerController:
	return Controller.get_instigator(primary_player)

func get_controllers_for_peer(peer_id: int) -> Array[PlayerController]:
	var result: Array[PlayerController] = []
	if peer_id == multiplayer.get_unique_id():
		for local_player: LocalPlayer in get_local_players():
			var controller: PlayerController = Controller.get_instigator(local_player)
			if controller: result.push_back(controller)
	else:
		# TODO: Handle multiple controllers from a remote client
		var remote_player := get_remote_player(peer_id)
		var controller := Controller.get_instigator(remote_player)
		if controller: result.push_back(controller)
	return result

func _spawn_controller(peer_id: int) -> PlayerController:
	var player_controller := _create_controller(peer_id)
	player_controller.net_owner = peer_id
	if peer_id == multiplayer.get_unique_id():
		# TODO: Handle multiple local players
		player_controller.player = primary_player
		player_controller.claim(primary_player)
	else:
		player_controller.player = get_remote_player(peer_id)
	player_joined.emit.call_deferred(player_controller)
	player_controller.tree_exiting.connect(_player_exiting.bind(player_controller), ConnectFlags.CONNECT_ONE_SHOT)
	return player_controller

func _create_controller(peer_id: int) -> PlayerController:
	var player_controller: PlayerController = _player_scene.instantiate() if _player_scene else PlayerController.new()
	player_controller.name = str(peer_id)
	return player_controller

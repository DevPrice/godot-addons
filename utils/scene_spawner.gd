class_name SceneSpawner extends MultiplayerSpawner

func _init() -> void:
	spawn_function = _spawn_scene

func _spawn_scene(data: Dictionary) -> Node:
	var scene_path: String = data["scene"]
	var properties: Dictionary = data["properties"]
	var scene: PackedScene = load(scene_path)
	var node: Node = scene.instantiate()
	for property: String in properties:
		node.set_indexed(property, properties[property])
	return node

func spawn_scene(scene_path: String, properties: Dictionary[NodePath, Variant]) -> Node:
	return spawn({
		"scene": scene_path,
		"properties": properties,
	})

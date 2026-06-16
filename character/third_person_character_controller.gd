class_name ThirdPersonCharacterController extends CharacterBody3D

@export var movement_speed: float = 6.0
@export var mass: float = 0.1
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir: Vector2 = _get_movement_input()
	var movement_strength: float = input_dir.length()

	var camera: Camera3D = get_viewport().get_camera_3d()
	var movement_basis: Basis = Basis(Vector3.UP, camera.global_rotation.y)
	var raw_direction: Vector3 = movement_basis * Vector3(input_dir.x, 0, input_dir.y)
	var direction: Vector3 = raw_direction.normalized() * movement_strength

	if direction:
		look_at(global_position + Vector3(direction.x, 0.0, direction.z))
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)

	var speed := velocity.length()
	var v := velocity

	if move_and_slide() and speed > 0.0:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var c := collision.get_collider()
			if c is RigidBody3D:
				var impact_speed := v.dot(-collision.get_normal())
				if impact_speed > 0.0:
					var impulse := mass * impact_speed
					c.apply_force(-collision.get_normal() * impulse, collision.get_position() - c.global_position)

func _get_movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

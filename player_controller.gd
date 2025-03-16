@tool
extends RadialQuadripedController

const SPEED:float = 10

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		var input_dir:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction:Vector3 = ((transform.basis * Vector3(input_dir.x, 0, input_dir.y))
				.normalized().rotated(Vector3.UP,body.global_rotation.y + PI))
		if direction:
			body_velocity.x = direction.x * SPEED
			body_velocity.z = direction.z * SPEED
		else:
			body_velocity = Vector3.ZERO

		if Input.is_action_pressed("ui_accept"):
			body_rotation.y += delta
		if Input.is_action_pressed("ui_cancel"):
			body_rotation.y -= delta
	super._physics_process(delta)

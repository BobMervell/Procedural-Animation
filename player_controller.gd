@tool
extends Node3D

const SPEED:float = 7
@onready var procedural_controller: RadialQuadripedController = $RadialQuadripedController


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		var input_dir:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction:Vector3 = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)) .normalized()
		if direction:
			procedural_controller.target_position_2D.x += direction.x * SPEED * delta
			procedural_controller.target_position_2D.y += direction.z * SPEED * delta

		if Input.is_action_pressed("ui_accept"):
			procedural_controller.target_rotation_y += delta
		if Input.is_action_pressed("ui_cancel"):
			procedural_controller.target_rotation_y -= delta

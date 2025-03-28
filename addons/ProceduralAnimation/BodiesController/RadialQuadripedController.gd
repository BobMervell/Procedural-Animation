@tool
extends Node3D
class_name RadialQuadripedController

## front left leg node
@export var front_left_leg:ThreeSegmentLegClass
## front right leg node
@export var front_right_leg:ThreeSegmentLegClass
## hind right leg node
@export var hind_right_leg:ThreeSegmentLegClass
## hind left leg node
@export var hind_left_leg:ThreeSegmentLegClass
## main body node
@export var body:Node3D
## Target position in a top down view (x,z)
@export var target_position_2D:Vector2
##Target rotation along the y axis
@export_range(0,2*PI,.001) var target_rotation_y:float
## desired body height
@export var body_desired_height:float = 3
## The speed at which the body aligns itself with the ground's angle.
@export_range(0,.5,.001) var tilt_speed:float = .1
@export_group("Move second order")
## Configuration weights for move second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation
@export var _move_second_order_config:Dictionary:
	set(new_value):
		_move_second_order_config = new_value
		_move_second_order = SecondOrderSystem.new(_move_second_order_config)
## Second order controller
@export var _move_second_order:SecondOrderSystem

@export_group("Rotate second order")
## Configuration weights for rotation second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation
@export var _rotation_second_order_config:Dictionary:
	set(new_value):
		_rotation_second_order_config = new_value
		_rotation_second_order = SecondOrderSystem.new(_rotation_second_order_config)
## Second order controller
@export var _rotation_second_order:SecondOrderSystem


##list of legs
var _legs:Array[ThreeSegmentLegClass]
## list of first diagonal legs
var _diagonal_legs_1:Array[ThreeSegmentLegClass]
## list of second diagonal legs
var _diagonal_legs_2:Array[ThreeSegmentLegClass]
## last body position
var _old_body_pos:Vector3
## used to verify if moved via target_position_2D or directly
var _old_estimated_position_2D:Vector2
## used to verify if rotated via target_rotation_y or directly
var _old_estimated_direction_y:float

#region Setup

func _ready() -> void:
	if not (front_left_leg and front_right_leg and hind_right_leg
				and hind_right_leg and body): return
	_initiate_controller()

func _initiate_controller() -> void:
	_initiate_body()
	_reset_legs_orientation()
	_initiate_legs_dictionnaries()
	for leg:ThreeSegmentLegClass in _legs:
		_initiate_leg_variables(leg)

func _initiate_body() -> void:
	_old_body_pos = body.global_position
	target_position_2D = Vector2(body.global_position.x,body.global_position.z)
	_old_estimated_position_2D = target_position_2D
	target_rotation_y = body.rotation.y
	_move_second_order = SecondOrderSystem.new(_move_second_order_config)
	_rotation_second_order = SecondOrderSystem.new(_rotation_second_order_config)

func _reset_legs_orientation() -> void:
	front_left_leg.rotation.y = -PI/4
	front_right_leg.rotation.y = -3*PI/4
	hind_right_leg.rotation.y = 3*PI/4
	hind_left_leg.rotation.y = PI/4

func _initiate_legs_dictionnaries() -> void:
	_legs.append(front_left_leg)
	_legs.append(front_right_leg)
	_legs.append(hind_right_leg)
	_legs.append(hind_left_leg)
	_diagonal_legs_1.append(front_left_leg)
	_diagonal_legs_1.append(hind_right_leg)
	_diagonal_legs_2.append(front_right_leg)
	_diagonal_legs_2.append(hind_left_leg)

func _initiate_leg_variables(leg:ThreeSegmentLegClass) -> void:
	leg.base.rotation.y = 0
	leg.movement_dir = Vector3.ZERO
	leg.leg_height = body_desired_height
#endregion


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if not (front_left_leg and front_right_leg and hind_right_leg
				and hind_right_leg and body): return
		if _diagonal_legs_1.is_empty():
			call_deferred("_initiate_controller")
	_move_body(delta)
	_move_legs(delta)
	_update_body_height(delta)
	_rotate_body(delta)
	_tilt_body()
	_old_body_pos = body.global_position




#region Body movements

func _move_body(delta:float) -> void:
	var new_pos2D:Vector2 = Vector2(body.global_position.x,body.global_position.z)
	if (_old_estimated_position_2D.is_equal_approx(new_pos2D)):
		new_pos2D = _move_second_order.vec2_second_order_response(
				delta,target_position_2D,new_pos2D)["output"]
		body.global_position.x = new_pos2D.x
		body.global_position.z = new_pos2D.y
	else:
		target_position_2D = Vector2(body.global_position.x,body.global_position.z)
	_old_estimated_position_2D = new_pos2D

func _rotate_body(delta:float) -> void:
	var real_direction:Vector2 = Vector2.from_angle(body.rotation.y)
	var angle_difference:float = abs(atan2(sin(_old_estimated_direction_y - body.rotation.y),
			cos(_old_estimated_direction_y - body.rotation.y)))
	if (angle_difference < .0001):
		var desired_direction:Vector2 = Vector2.from_angle(target_rotation_y)
		real_direction = _rotation_second_order.vec2_second_order_response(
				delta,desired_direction,real_direction)["output"]
		body.rotation.y = real_direction.angle()
	else:
		target_rotation_y = body.rotation.y
	_old_estimated_direction_y = body.rotation.y

func _update_body_height(delta:float) -> void:
	var mean_height:float = 0
	for leg:ThreeSegmentLegClass in _legs:
		mean_height += leg.rest_pos.y
	mean_height = get_ground_level() - body_desired_height
	# able to use same second order as _move_body() cause different method (float vs vector2)
	var target_height:float = mean_height + body_desired_height
	body.global_position.y = _move_second_order.float_second_order_response(delta,
			target_height, body.global_position.y,)["output"]

func get_ground_level() -> float:
	var target_height:float = body.global_position.y
	var max_length:float = (front_left_leg.segment_1.segment_length  +
			front_left_leg.segment_2.segment_length +
			front_left_leg.segment_3.segment_length)
	var query_start:Vector3 = body.global_position
	var query_limit:Vector3 = query_start + Vector3(0,-max_length,0)
	var query:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(query_start,query_limit)
	query.collide_with_areas = true
	var result:Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		# able to use same second order as _move_body() cause different method (float vs vector2)
		target_height = result["position"].y + body_desired_height
	return target_height

func _tilt_body() -> void:
	var front_height:float = (front_left_leg.rest_pos.y + front_right_leg.rest_pos.y)*.5
	var hind_height:float = (hind_left_leg.rest_pos.y + hind_right_leg.rest_pos.y)*.5
	var left_height:float = (front_left_leg.rest_pos.y + hind_left_leg.rest_pos.y)*.5
	var right_height:float = (front_right_leg.rest_pos.y + hind_right_leg.rest_pos.y)*.5
	var x_size:float = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		front_right_leg.to_global(front_right_leg.rest_pos))
	var z_size:float = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		hind_left_leg.to_global(hind_left_leg.rest_pos))
	var x_angle:float = asin((hind_height - front_height)/z_size)
	var z_angle:float = asin((left_height - right_height)/x_size)

	rotation.x = x_angle
	rotation.z = z_angle
	body.rotation.x = lerp(body.rotation.x,rotation.x,tilt_speed)
	body.rotation.z = lerp(body.rotation.z,rotation.z,tilt_speed)
#endregion


func _move_legs(delta:float):
	for leg: ThreeSegmentLegClass in _get_returning_pair():
		leg.rest_pos = leg.get_rest_pos()
		leg.is_returning = true
	for leg:ThreeSegmentLegClass in _legs:
		var movement_dir = ((body.position -_old_body_pos)/delta).normalized()
		leg.movement_dir = lerp(leg.movement_dir,movement_dir,.05)
		if leg.is_returning:
			leg.target_marker.position = leg.get_returning_position(delta,leg.target_marker.position)
			if leg.is_return_phase_finished():
				leg.global_current_ground_pos = leg.to_global(leg.rest_pos)
				leg.is_returning = false
		else:
			leg.target_marker.global_position = leg.global_current_ground_pos

func _get_returning_pair() -> Array[ThreeSegmentLegClass]:
	for leg:ThreeSegmentLegClass in _legs:
		if (leg.desired_state == leg.DesiredState.MUST_RESTEP or leg.is_returning):
			if _diagonal_legs_1.has(leg):
				return _diagonal_legs_1
			return _diagonal_legs_2
	for leg:ThreeSegmentLegClass in _legs: # need a second pass because needs_restep not priority
		if leg.desired_state == leg.DesiredState.NEEDS_RESTEP:
			if _diagonal_legs_1.has(leg): return _diagonal_legs_1
			return _diagonal_legs_2
	return []


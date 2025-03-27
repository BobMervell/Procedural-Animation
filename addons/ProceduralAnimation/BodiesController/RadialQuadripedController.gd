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

## positions of legs end on ground
var _grounded_target_pos:Dictionary
## list of legs on ground
var _grounded_legs:Array[ThreeSegmentLegClass]
## list of legs returning to resting position
var _returning_legs:Array[ThreeSegmentLegClass]
## list of first diagonal legs
var _diagonal_legs_1:Array[ThreeSegmentLegClass]
## list of second diagonal legs
var _diagonal_legs_2:Array[ThreeSegmentLegClass]

## heights of each leg (uneven or inclined terrain)
var _leg_heights:Dictionary
## last body position
var _old_body_pos:Vector3
## Main body rotation.
## [br][b][color=red]Warning:[/color][/b] Use this instead of ThreeSegmentLegClass.rotation to control character
var body_rotation:Vector3

@export var __body_target_pos_2D:Vector2
@export var __body_target_rota_y:Vector3
var __old_estimated_position:Vector2 # used to verify if moved via body_target or directly
var __old_estimated_direction_y:float

#region Setup

func _ready() -> void:
	if not (front_left_leg and front_right_leg and hind_right_leg
				and hind_right_leg and body): return
	_initiate_controller()

func _initiate_controller() -> void:
	_initiate_body()
	_reset_legs_orientation()
	_initiate_legs_dictionnaries()
	for leg:ThreeSegmentLegClass in _grounded_legs:
		_initiate_leg_variables(leg)

func _initiate_body() -> void:
	_old_body_pos = body.global_position
	__body_target_pos_2D = Vector2(body.global_position.x,body.global_position.z)
	__old_estimated_position = __body_target_pos_2D
	__body_target_rota_y = body.rotation
	_move_second_order = SecondOrderSystem.new(_move_second_order_config)
	_rotation_second_order = SecondOrderSystem.new(_rotation_second_order_config)
	print(_rotation_second_order_config)

func _reset_legs_orientation() -> void:
	front_left_leg.rotation.y = -PI/4
	front_right_leg.rotation.y = -3*PI/4
	hind_right_leg.rotation.y = 3*PI/4
	hind_left_leg.rotation.y = PI/4

func _initiate_legs_dictionnaries() -> void:
	_grounded_legs.append(front_left_leg)
	_grounded_legs.append(front_right_leg)
	_grounded_legs.append(hind_right_leg)
	_grounded_legs.append(hind_left_leg)
	_diagonal_legs_1.append(front_left_leg)
	_diagonal_legs_1.append(hind_right_leg)
	_diagonal_legs_2.append(front_right_leg)
	_diagonal_legs_2.append(hind_left_leg)

func _initiate_leg_variables(leg:ThreeSegmentLegClass) -> void:
	leg.base.rotation.y = 0
	leg.movement_dir = Vector3.ZERO
	leg.leg_height = body_desired_height
	_grounded_target_pos[leg] = leg.to_global(leg.get_rest_pos())
	_leg_heights[leg] = 0
#endregion


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if not (front_left_leg and front_right_leg and hind_right_leg
				and hind_right_leg and body): return
		if _diagonal_legs_1.is_empty():
			call_deferred("_initiate_controller")
	_get_leg_heights()
	_move_body(delta)
	_update_body_height(delta)
	_rotate_body(delta)
	_tilt_body()
	_update_legs_variables(delta)
	_old_body_pos = body.global_position

#region Body movements

func _move_body(delta:float) -> void:
	var new_pos2D:Vector2 = Vector2(body.global_position.x,body.global_position.z)
	if (__old_estimated_position.is_equal_approx(new_pos2D)):
		new_pos2D = _move_second_order.vec2_second_order_response(
				delta,__body_target_pos_2D,new_pos2D)["output"]
		body.global_position.x = new_pos2D.x
		body.global_position.z = new_pos2D.y
	else:
		__body_target_pos_2D = Vector2(body.global_position.x,body.global_position.z)
	__old_estimated_position = new_pos2D

func _rotate_body(delta:float) -> void:
	var real_direction:Vector2 = Vector2.from_angle(body.rotation.y)
	var angle_difference:float = abs(atan2(sin(__old_estimated_direction_y - body.rotation.y),
			cos(__old_estimated_direction_y - body.rotation.y)))
	if (angle_difference < .0001):
		var desired_direction:Vector2 = Vector2.from_angle(__body_target_rota_y.y)
		real_direction = _rotation_second_order.vec2_second_order_response(
				delta,desired_direction,real_direction)["output"]
		body.rotation.y = real_direction.angle()
	else:
		__body_target_rota_y.y = body.rotation.y
	__old_estimated_direction_y = body.rotation.y


func _update_body_height(delta:float) -> void:
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
		var target_height:float = result["position"].y + body_desired_height
		body.global_position.y = _move_second_order.float_second_order_response(delta,
				target_height, body.global_position.y,)["output"]

func _tilt_body() -> void:
	var front_height:float = (_leg_heights[front_left_leg] + _leg_heights[front_right_leg])*.5
	var hind_height:float = (_leg_heights[hind_left_leg] + _leg_heights[hind_right_leg])*.5
	var left_height:float = (_leg_heights[front_left_leg] + _leg_heights[hind_left_leg])*.5
	var right_height:float = (_leg_heights[front_right_leg] + _leg_heights[hind_right_leg])*.5
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

func _get_leg_heights() -> void:
	for leg:ThreeSegmentLegClass in _leg_heights:
		if leg.desired_state == leg.DesiredState.OK_ON_GROUND:
			_leg_heights[leg] = leg.segment_3.segment_end.global_position.y

## update legs end position and returning state
func _update_legs_variables(delta:float) -> void:
	_old_body_pos.direction_to(body.position)
	var movement_dir:Vector3 = _old_body_pos.direction_to(body.position)
	movement_dir.y = 0 #discard y movement
	for leg:ThreeSegmentLegClass in _get_returning_pair():
		_returning_legs.append(leg)
		leg.is_returning = true
	for leg:ThreeSegmentLegClass in _grounded_legs:
		if movement_dir != Vector3.ZERO: leg.movement_dir = movement_dir
		@warning_ignore("unsafe_call_argument")
		leg.target_marker.position = leg.to_local(_grounded_target_pos[leg])
	for leg:ThreeSegmentLegClass in _returning_legs:
		if movement_dir != Vector3.ZERO: leg.movement_dir = movement_dir
		_return_to_rest(leg,delta)

## get leg pair which needs the most a restep
func _get_returning_pair() -> Array[ThreeSegmentLegClass]:
	# worst case check twice each legs (4*2 in total)
	var anticipated_lift:bool = true
	for leg:ThreeSegmentLegClass in _returning_legs:
		anticipated_lift = ( anticipated_lift and
				leg.returning_phase == leg.ReturningPhase.BACK_SWING)
	if not anticipated_lift: return []
	for leg:ThreeSegmentLegClass in _grounded_legs:
		if leg.desired_state == leg.DesiredState.MUST_RESTEP:
			if _diagonal_legs_1.has(leg): return _diagonal_legs_1
			return _diagonal_legs_2
	for leg:ThreeSegmentLegClass in _grounded_legs:
		if leg.desired_state == leg.DesiredState.NEEDS_RESTEP:
			if _diagonal_legs_1.has(leg): return _diagonal_legs_1
			return _diagonal_legs_2
	return []

## move leg target to resting_position
func _return_to_rest(leg:ThreeSegmentLegClass,delta:float) -> void:
	var leg_rest:Vector3 = leg.get_rest_pos()
	if _grounded_legs.has(leg): _grounded_legs.erase(leg)
	if leg.target_marker.position.distance_squared_to(leg_rest) < leg.target_sensibility_treshold: # is_equal_approx to sensible
		_grounded_legs.append(leg)
		_returning_legs.erase(leg)
		_grounded_target_pos[leg] = leg.to_global(leg_rest)
	leg.target_marker.position = leg.get_returning_position(delta,leg.target_marker.position)

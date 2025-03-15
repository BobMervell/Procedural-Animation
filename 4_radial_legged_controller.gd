@tool
extends Node3D
class_name RadialQuadripedController

@export var front_left_leg:ThreeSegmentLeg
@export var front_right_leg:ThreeSegmentLeg
@export var hind_right_leg:ThreeSegmentLeg
@export var hind_left_leg:ThreeSegmentLeg
@export var body:CharacterBody3D

## height of legs base
@export var body_desired_height:float = 4

@export_group("Move second order")
@export var move_second_order_config:Dictionary:
	set(new_value):
		move_second_order_config = new_value
		move_second_order = SecondOrderSystem.new(move_second_order_config)
@export var move_second_order:SecondOrderSystem

@export_group("Rotate second order")
@export var rotation_second_order_config:Dictionary:
	set(new_value):
		rotation_second_order_config = new_value
		rotation_second_order = SecondOrderSystem.new(rotation_second_order_config)
@export var rotation_second_order:SecondOrderSystem


var grounded_target_pos:Dictionary
var grounded_legs:Array[ThreeSegmentLeg]
var returning_legs:Array[ThreeSegmentLeg]
var diagonal_legs_1:Array[ThreeSegmentLeg]
var diagonal_legs_2:Array[ThreeSegmentLeg]

var leg_heights:Dictionary
var old_body_pos:Vector3
var body_velocity:Vector3
var body_rotation:Vector3

#region Setup
func _ready() -> void:
	_initiate_controller()

func _initiate_controller() -> void:
	_initiate_body()
	_reset_legs_orientation()
	_initiate_legs_dictionnaries()
	for leg:ThreeSegmentLeg in grounded_legs:
		_initiate_leg_variables(leg)

func _initiate_body() -> void:
	body.global_position = global_position
	old_body_pos = global_position
	move_second_order = SecondOrderSystem.new(move_second_order_config)
	rotation_second_order = SecondOrderSystem.new(rotation_second_order_config)

func _reset_legs_orientation() -> void:
	front_left_leg.rotation.y = -PI/4
	front_right_leg.rotation.y = -3*PI/4
	hind_right_leg.rotation.y = 3*PI/4
	hind_left_leg.rotation.y = PI/4

func _initiate_legs_dictionnaries() -> void:
	grounded_legs.append(front_left_leg)
	grounded_legs.append(front_right_leg)
	grounded_legs.append(hind_right_leg)
	grounded_legs.append(hind_left_leg)
	diagonal_legs_1.append(front_left_leg)
	diagonal_legs_1.append(hind_right_leg)
	diagonal_legs_2.append(front_right_leg)
	diagonal_legs_2.append(hind_left_leg)

func _initiate_leg_variables(leg:ThreeSegmentLeg) -> void:
	leg.base.rotation.y = 0
	leg.movement_dir = Vector3.ZERO
	leg.leg_height = body_desired_height
	grounded_target_pos[leg] = leg.to_global(leg.get_rest_pos())
	leg_heights[leg] = 0
#endregion


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if diagonal_legs_1.is_empty():
			call_deferred("_initiate_controller")
		else:
			body_rotation = rotation
			body_velocity = (global_position - old_body_pos)/delta
	update_legs_variables(delta)
	get_leg_heights()
	move_body(delta)
	update_body_height()
	rotate_body(delta)
	tilt_body()
	old_body_pos = global_position

#region Body movements
func move_body(delta:float) -> void:
	body.velocity = move_second_order.vec3_second_order_response(
			delta,body_velocity,body.velocity)["output"]
	body.velocity.y = 0
	@warning_ignore("return_value_discarded")
	body.move_and_slide()

func rotate_body(delta:float) -> void:
	var desired_direction:Vector2 = Vector2.from_angle(body_rotation.y)
	var real_direction:Vector2 = Vector2.from_angle(body.rotation.y)
	real_direction = rotation_second_order.vec2_second_order_response(
			delta,desired_direction,real_direction)["output"]
	body.rotation.y = real_direction.angle()

func update_body_height() -> void:
	var max_length:float = (front_left_leg.segment_1.segment_length  +
			front_left_leg.segment_2.segment_length +
			front_left_leg.segment_3.segment_length)
	var query_start:Vector3 = body.global_position
	var query_limit:Vector3 = query_start + Vector3(0,-max_length,0)
	var query:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(query_start,query_limit)
	query.collide_with_areas = true
	var result:Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		global_position.y = lerp(body.global_position.y,result["position"].y + body_desired_height,.1)
		body.global_position.y = global_position.y

func tilt_body() -> void:
	var front_height:float = (leg_heights[front_left_leg] + leg_heights[front_right_leg])*.5
	var hind_height:float = (leg_heights[hind_left_leg] + leg_heights[hind_right_leg])*.5
	var left_height:float = (leg_heights[front_left_leg] + leg_heights[hind_left_leg])*.5
	var right_height:float = (leg_heights[front_right_leg] + leg_heights[hind_right_leg])*.5
	var x_size:float = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		front_right_leg.to_global(front_right_leg.rest_pos))
	var z_size:float = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		hind_left_leg.to_global(hind_left_leg.rest_pos))
	var x_angle:float = asin((hind_height - front_height)/z_size)
	var z_angle:float = asin((left_height - right_height)/x_size)

	rotation.x = x_angle
	rotation.z = z_angle
	body.rotation.x = lerp(body.rotation.x,rotation.x,.1)
	body.rotation.z = lerp(body.rotation.z,rotation.z,.1)
#endregion

func get_leg_heights() -> void:
	for leg:ThreeSegmentLeg in leg_heights:
		if not leg.is_returning:
			leg_heights[leg] = leg.segment_3.segment_end.global_position.y

func update_legs_variables(delta:float) -> void:
	var movement_dir:Vector3 = Vector3(body_velocity.x,0,body_velocity.z).normalized()#discard y movement
	for leg:ThreeSegmentLeg in get_returning_pair():
		returning_legs.append(leg)

	for leg:ThreeSegmentLeg in grounded_legs:
		if movement_dir != Vector3.ZERO: leg.movement_dir = movement_dir
		leg.is_returning = false
		@warning_ignore("unsafe_call_argument")
		leg.target_marker.position = leg.to_local(grounded_target_pos[leg])
	for leg:ThreeSegmentLeg in returning_legs:
		if movement_dir != Vector3.ZERO: leg.movement_dir = movement_dir
		leg.is_returning = true
		return_to_rest(leg,delta)

func get_returning_pair() -> Array[ThreeSegmentLeg]:
	# worst case check twice each legs (4*2 in total)
	var anticipated_lift:bool = true
	for leg:ThreeSegmentLeg in returning_legs:
		anticipated_lift = ( anticipated_lift and
				leg.returning_phase == leg.ReturningPhase.BACK_SWING)
	if not anticipated_lift: return []
	for leg:ThreeSegmentLeg in grounded_legs:
		if leg.desired_state == leg.DesiredState.MUST_RESTEP:
			if diagonal_legs_1.has(leg): return diagonal_legs_1
			return diagonal_legs_2
	for leg:ThreeSegmentLeg in grounded_legs:
		if leg.desired_state == leg.DesiredState.NEEDS_RESTEP:
			if diagonal_legs_1.has(leg): return diagonal_legs_1
			return diagonal_legs_2
	return []

func return_to_rest(leg:ThreeSegmentLeg,delta:float) -> void:
	var leg_rest:Vector3 = leg.get_rest_pos()
	if grounded_legs.has(leg): grounded_legs.erase(leg)
	if leg.target_marker.position.distance_squared_to(leg_rest) < .0001:
		grounded_legs.append(leg)
		returning_legs.erase(leg)
		grounded_target_pos[leg] = leg.to_global(leg_rest)
	leg.target_marker.position = leg.get_returning_position(delta,leg.target_marker.position)

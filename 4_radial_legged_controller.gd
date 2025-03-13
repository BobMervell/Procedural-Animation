@tool
extends Node3D

@export var front_left_leg:ThreeSegmentLeg
@export var front_right_leg:ThreeSegmentLeg
@export var hind_right_leg:ThreeSegmentLeg
@export var hind_left_leg:ThreeSegmentLeg
@export var body_target:Marker3D

var grounded_target_pos:Dictionary
var grounded_legs:Array[ThreeSegmentLeg]
var returning_legs:Array[ThreeSegmentLeg]
var diagonal_legs_1:Array[ThreeSegmentLeg]
var diagonal_legs_2:Array[ThreeSegmentLeg]
var returning_legs_selected:bool = false
var old_position:Vector3
@export var body_direction_impact:float = 1.2

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

@export_group("Tilt second order")
@export var tilt_second_order_config:Dictionary:
	set(new_value):
		tilt_second_order_config = new_value
		tilt_second_order = SecondOrderSystem.new(tilt_second_order_config)
@export var tilt_second_order:SecondOrderSystem

func _initiate_editor() -> void:
	move_second_order = SecondOrderSystem.new(move_second_order_config)
	rotation_second_order = SecondOrderSystem.new(rotation_second_order_config)
	tilt_second_order = SecondOrderSystem.new(tilt_second_order_config)

	front_left_leg.rotation.y = -PI/4
	front_right_leg.rotation.y = -3*PI/4
	hind_right_leg.rotation.y = 3*PI/4
	hind_left_leg.rotation.y = PI/4
	grounded_legs.append(front_left_leg)
	grounded_legs.append(front_right_leg)
	grounded_legs.append(hind_right_leg)
	grounded_legs.append(hind_left_leg)
	diagonal_legs_1.append(front_left_leg)
	diagonal_legs_1.append(hind_right_leg)
	diagonal_legs_2.append(front_right_leg)
	diagonal_legs_2.append(hind_left_leg)
	for leg:ThreeSegmentLeg in grounded_legs:
		leg.parent_rest_pos = get_parent_rest_pos(leg)
		grounded_target_pos[leg] = leg.to_global(leg.get_rest_pos())

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if ( not grounded_target_pos or (
				grounded_target_pos[front_left_leg] == Vector3.ZERO
				) ):
			call_deferred("_initiate_editor")
		else:
			
			returning_legs_selected = false
			
			for leg in check_return_trot():
				returning_legs.append(leg)
			
			for leg:ThreeSegmentLeg in grounded_legs:
				leg.parent_rest_pos = get_parent_rest_pos(leg)
				leg.is_returning = false
				leg.target_marker.position = leg.to_local(grounded_target_pos[leg])
			for leg:ThreeSegmentLeg in returning_legs:
				leg.parent_rest_pos = get_parent_rest_pos(leg)
				leg.is_returning = true
				return_to_rest(leg,delta)
		old_position = position

func check_return_trot() -> Array[ThreeSegmentLeg]:
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

func get_parent_rest_pos(leg:ThreeSegmentLeg) -> Vector2:
	var leg_dir:Vector3 = leg.to_local(global_position).direction_to(leg.base.position)
	var rest_pos:Vector2 = Vector2(leg_dir.x,leg_dir.z).normalized() * leg.rest_distance
	var movement_dir = leg.to_local(old_position).direction_to(
				leg.to_local(position))
	var movement_dir2D = Vector2(movement_dir.x,movement_dir.z).normalized()
	rest_pos +=  movement_dir2D * body_direction_impact
	return rest_pos

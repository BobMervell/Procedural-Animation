@tool
extends Node3D

@export var front_left_leg:ThreeSegmentLeg
@export var front_right_leg:ThreeSegmentLeg
@export var hind_right_leg:ThreeSegmentLeg
@export var hind_left_leg:ThreeSegmentLeg
@export var body:CharacterBody3D

var grounded_target_pos:Dictionary
var grounded_legs:Array[ThreeSegmentLeg]
var returning_legs:Array[ThreeSegmentLeg]
var diagonal_legs_1:Array[ThreeSegmentLeg]
var diagonal_legs_2:Array[ThreeSegmentLeg]
var returning_legs_selected:bool = false
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

@export_group("Tilt second order")
@export var tilt_second_order_config:Dictionary:
	set(new_value):
		tilt_second_order_config = new_value
		tilt_x_second_order = SecondOrderSystem.new(tilt_second_order_config)
		tilt_z_second_order = SecondOrderSystem.new(tilt_second_order_config)
		height_second_order = SecondOrderSystem.new(tilt_second_order_config)
@export var tilt_second_order:SecondOrderSystem

var tilt_x_second_order:SecondOrderSystem
var tilt_z_second_order:SecondOrderSystem
var height_second_order:SecondOrderSystem

var leg_heights:Dictionary
var old_body_pos:Vector3
var body_velocity:Vector3
var body_rotation:Vector3

func _initiate_editor() -> void:
	body.global_position = global_position
	old_body_pos = global_position
	move_second_order = SecondOrderSystem.new(move_second_order_config)
	rotation_second_order = SecondOrderSystem.new(rotation_second_order_config)
	tilt_x_second_order = SecondOrderSystem.new(tilt_second_order_config)
	tilt_z_second_order = SecondOrderSystem.new(tilt_second_order_config)
	height_second_order = SecondOrderSystem.new(tilt_second_order_config)

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
		leg.base.rotation.y = 0
		leg.movement_dir = Vector3.ZERO
		leg.leg_height = body_desired_height
		grounded_target_pos[leg] = leg.to_global(leg.get_rest_pos())
		leg_heights[leg] = 0

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if ( not grounded_target_pos or (
				grounded_target_pos[front_left_leg] == Vector3.ZERO
				) ):
			call_deferred("_initiate_editor")
		else:
			update_body_state(delta)
			update_legs(delta)
			get_leg_heights()
			move_body(delta)
			update_body_height()
			body.rotation.y = get_second_order_angle(delta,body.rotation.y,body_rotation.y)
			tilt_body(delta)
			old_body_pos = global_position

func update_body_state(delta:float):
	if Engine.is_editor_hint():
		body_velocity = (global_position - old_body_pos)/delta
		
	else: pass
	body_rotation = rotation

func move_body(delta:float) -> void:
	body.velocity = move_second_order.vec3_second_order_response(
			delta,body_velocity,body.velocity)["output"]
	body.velocity.y = 0
	body.move_and_slide()

func get_leg_heights():
	for leg:ThreeSegmentLeg in leg_heights:
		if not leg.is_returning:
			leg_heights[leg] = leg.segment_3.segment_end.global_position.y

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

func update_tilt() -> void:
	var front_height = max(leg_heights[front_left_leg],leg_heights[front_right_leg])
	var hind_height = max(leg_heights[hind_left_leg],leg_heights[hind_right_leg])
	var left_height = max(leg_heights[front_left_leg],leg_heights[hind_left_leg])
	var right_height = max(leg_heights[front_right_leg],leg_heights[hind_right_leg])
	var x_size = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		front_right_leg.to_global(front_right_leg.rest_pos))
	var z_size = front_left_leg.to_global(front_left_leg.rest_pos).distance_to(
		hind_left_leg.to_global(hind_left_leg.rest_pos))
	
	
	var x_angle = asin((hind_height - front_height)/z_size)
	var z_angle = asin((left_height - right_height)/x_size)
	#print(deg_to_rad(rotation.x-x_angle))
	#print(front_height - hind_height)
	#print(asin((1)))
	rotation.x = x_angle
	rotation.z = z_angle

func tilt_body(delta:float) -> void:
	update_tilt()
	#print(leg_heights)
	#print(rad_to_deg(rotation.x))
	body.rotation.x = lerp(body.rotation.x,rotation.x,.05)
	body.rotation.z = lerp(body.rotation.z,rotation.z,.05)
	#body.rotation.z = rotation.z
	#body.rotation.x = get_second_order_angle(delta,body.rotation.x,body_rotation.x)
	#body.rotation.z = get_second_order_angle(delta,body.rotation.z,body_rotation.z)

func get_second_order_angle(delta:float,current_angle,new_angle) -> float:
	var desired_direction:Vector2 = Vector2.from_angle(new_angle)
	var real_direction:Vector2 = Vector2.from_angle(current_angle)
	real_direction = rotation_second_order.vec2_second_order_response(
			delta,desired_direction,real_direction)["output"]
	return real_direction.angle()

func update_legs(delta:float) -> void:
	returning_legs_selected = false
	var movement_dir = old_body_pos.direction_to(global_position)
	movement_dir = Vector3(movement_dir.x,0,movement_dir.z).normalized()#discard y movement
	for leg in get_returning_pair():
		returning_legs.append(leg)
	
	for leg:ThreeSegmentLeg in grounded_legs:
		if movement_dir != Vector3.ZERO: leg.movement_dir = movement_dir
		leg.is_returning = false
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

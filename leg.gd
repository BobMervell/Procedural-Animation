@tool
extends Node3D
class_name ThreeSegmentLeg

const MARKER:PackedScene = preload("res://marker.tscn")

@export_group("Simulation details")
## Activates a walk cycle simulation.
@export var walk_simulation:bool = false
## Controls the reaching height of the leg (arbitrary units, not real-world meters).
@export var simulation_extended_height:float = 0:
	set(new_value):
		if not (lengths and rest_pos): return
		simulation_extended_height = new_value 
		simulation_target.y = simulation_extended_height * 10
		var max_horizontal_length = get_max_horizontal_length()
		var current_horizontal_length = get_horizontal_length()
		var length_ratio:float = max(0,1 - current_horizontal_length/max_horizontal_length)
		target_marker.position.y = simulation_target.y * length_ratio
## Controls the rotation angle of the leg (in radians).
@export_range(-PI,PI,.01) var simulation_rotation:float = 0:
	set(new_value):
		simulation_rotation = new_value
		simulation_target.x = 10 * cos(simulation_rotation)
		simulation_target.z = 10 * sin(simulation_rotation)
		var current_target_dist:float = Vector2(target_marker.position.x,target_marker.position.z).length()
		target_marker.position.x = current_target_dist * cos(simulation_rotation)
		target_marker.position.z = current_target_dist * sin(simulation_rotation)
var simulation_target:Vector3


@export_group("Segment configuration")
@export_subgroup(("Base"))
@export var leg_vertical_offset:float = 0:
	set(new_value):
		leg_vertical_offset = new_value
		leg_offset.y = new_value
@export var leg_horizontal_offset:float = 0:
	set(new_value):
		leg_horizontal_offset = new_value
		leg_offset.x = new_value
var leg_offset:Vector3 = Vector3.ZERO
@export_subgroup("Segment 1")
## Controls the length of the segment (along the z axis).
@export_range(0,5,.01,"or_greater") var segment_1_length:float=1:
	set(new_value):
		if not segment_1: return
		segment_1_length = new_value
		segment_1.segment_length = new_value
		segment_1.update()
@export_subgroup("Segment 2")
## Controls the length of the segment (along the z axis).
@export_range(0,5,.01,"or_greater") var segment_2_length:float=1:
	set(new_value):
		if not segment_2: return
		segment_2_length = new_value
		segment_2.segment_length = new_value
		segment_2.update()
@export_subgroup("Segment 3")
## Controls the length of the segment (along the z axis).
@export_range(0,5,.01,"or_greater") var segment_3_length:float=1:
	set(new_value):
		if not segment_3: return
		segment_3_length = new_value
		segment_3.segment_length = new_value
		segment_3.update()



@export_group("Leg behavior")
## Distance of the resting position from the leg base.
@export var rest_distance:float = 1
## Trajectory followed by the leg when returning to the resting position.
@export var returning_trajectory:Curve
## Specifies the elbow configuration (up or down).
@export var elbow_up:bool = true
## Incidence angle of the third segment relative to the ground.
@export_range(0,PI,.01) var incidence_angle:float
## Controls the speed of leg's extension/retraction.
@export var extension_speed:float = 10
@export var move_direction_impact:float = 1.2

@export_subgroup("Rotation second order")
## Configuration weights for rotation second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation
@export var rota_second_order_config:Dictionary:
	set(new_value):
		rota_second_order_config = new_value
		rota_second_order = SecondOrderSystem.new(rota_second_order_config)
## Second order controller
@export var rota_second_order:SecondOrderSystem
var output_direction:Vector2


@export_subgroup("Extension second order")
## Configuration weights for extension second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation
@export var extension_second_order_config:Dictionary:
	set(new_value):
		extension_second_order_config = new_value
		extension_second_order = SecondOrderSystem.new(extension_second_order_config)
## Second order controller
@export var extension_second_order:SecondOrderSystem


@export_group("Markers")
## Displays markers at the beginning of each segment.
@export var show_begin_segment_markers:bool = true
## Defines the color of the markers at the beginning of each segment.
@export_color_no_alpha var begin_markers_color:Color = Color.BLACK
## Displays markers at the end of each segment.
@export var show_end_segment_markers:bool = true
## Defines the color of the markers at the end of each segment.
@export_color_no_alpha var end_markers_color:Color = Color.RED
## Display marker at the resting position.
@export var show_rest_pos_marker:bool = true
## Defines the color of the marker at the resting position.
@export_color_no_alpha var rest_pos_marker_color:Color = Color.GREEN
## Display marker at the targeted position.
@export var show_target_pos_marker:bool = true
## Defines the color of the markers at the targeted position.
@export_color_no_alpha var target_pos_marker_color:Color = Color.BLUE
@export var show_path:bool = true
var path_array:Array[Vector3]
var path_mesh:MeshInstance3D


var leg_height:float
var output_intermediate_target:Vector2
var last_extended_position:Vector3 = Vector3.ZERO
var rest_pos:Vector3
var lengths:Dictionary
var IK_variables:Dictionary
var is_returning:bool = true:
	set(new_value):
		if new_value and not is_returning: 
			var next_extended_position = to_local(segment_3.segment_end.global_position)
			if abs(next_extended_position) - abs(rest_pos) > Vector3.ZERO:
				last_extended_position = next_extended_position
		is_returning = new_value
		if is_returning: target_pos_marker_color = Color.MAGENTA
		else: target_pos_marker_color = Color.BLUE

var movement_dir:Vector3
enum ReturningPhase {LIFTING,MID_SWING,BACK_SWING}
var returning_phase = ReturningPhase.LIFTING
enum DesiredState {OK_ON_GROUND,NEEDS_RESTEP,MUST_RESTEP,RETURNING}
var desired_state = DesiredState.OK_ON_GROUND
var is_lifting:bool = false
var is_mid_swing:bool = false
var is_back_swing:bool = false

# leg's element
var base: LegSegment
var segment_1: LegSegment
var segment_2: LegSegment
var segment_3: LegSegment
var target_marker: Marker3D
var delete_childs:Array[Node3D] #can't delete all childs so keep count

#region Editor_setup
func _initate_editor() -> void:
	_get_nodes()
	output_intermediate_target = Vector2.ZERO
	output_direction = Vector2.ZERO
	rota_second_order = SecondOrderSystem.new(rota_second_order_config)
	extension_second_order = SecondOrderSystem.new(extension_second_order_config)
	simulation_rotation = 0
	simulation_extended_height = 0
	path_mesh = MeshInstance3D.new()
	add_child(path_mesh)

func _set_markers() -> void:
	var segments:Array = [segment_1,segment_2,segment_3]
	for segment:LegSegment in segments:
		segment.show_begin_marker = show_begin_segment_markers
		segment.show_end_marker = show_end_segment_markers
		segment.begin_marker_color = begin_markers_color
		segment.end_marker_color = end_markers_color
		segment.update()
	if show_rest_pos_marker:
		var marker:Node3D = _add_marker(rest_pos_marker_color)
		marker.position = rest_pos
	if show_target_pos_marker:
		var marker:Node3D = _add_marker(target_pos_marker_color)
		marker.position = target_marker.position

func _add_marker(color:Color) -> Node3D:
	var marker:Node3D = MARKER.instantiate()
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	for mesh:MeshInstance3D in marker.get_children():
		mesh.set_surface_override_material(0,material)
	add_child(marker)
	delete_childs.append(marker)
	return marker

func _update_segment_positions() -> void:
	segment_1.position = leg_offset
	segment_2.position.z = segment_1.segment_length 
	segment_3.position.z = segment_2.segment_length 

func _get_nodes() -> void:
	base = $Base
	target_marker = $Editor_target
	segment_1 = $Base/Segment_1
	segment_2 = $Base/Segment_1/Segment_2
	segment_3 = $Base/Segment_1/Segment_2/Segment_3
#endregion




func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		for child:Node in delete_childs:
			child.queue_free()
		delete_childs.clear()
		if not base:
			_initate_editor()
		_set_markers()
		_update_segment_positions() # to move in a setter later can't right now cause export variable in child.
		rest_pos = get_rest_pos()
		
		desired_state = DesiredState.OK_ON_GROUND
		
		if walk_simulation:
			target_marker.position = emulate_target_position(delta)
			
		IK_variables =  get_IK_variables(target_marker.position)
		rotate_base(delta)
		extend_arms(delta)
		update_returning_status()
		if show_path:
			path_array.append(to_local(segment_3.segment_end.global_position))



### FOLLOW TARGET

func get_IK_variables(target:Vector3) -> Dictionary:
	var start_pos:Vector3 = to_local(base.global_position)
	var top_down_tg:Vector2 = Vector2(target.x,target.z)
	var direction = Vector2(start_pos.x,start_pos.z).direction_to(top_down_tg)
	
	target -= leg_offset.rotated(Vector3.UP,base.rotation.y)
	top_down_tg = Vector2(target.x,target.z)
	
	var danger_margin: float = .2
	var diff:Vector2 = (top_down_tg-Vector2(start_pos.x,start_pos.z))
	if diff < Vector2.ZERO:
		desired_state = max(DesiredState.MUST_RESTEP,desired_state)
	elif diff < Vector2.ONE * danger_margin:
		desired_state = max(DesiredState.NEEDS_RESTEP,desired_state)
	
	var side_view_tg:Vector2 = Vector2(top_down_tg.length(),-target.y)
	var intermediate_tg:Vector2 = get_intermediate_target(segment_3.segment_length,side_view_tg)
	return {"top_down_tg":top_down_tg,"direction":direction,"intermediate_tg":intermediate_tg}

func rotate_base(delta:float) -> void:
	var direction:Vector2 = IK_variables["direction"]
	output_direction = rota_second_order.vec2_second_order_response(
			delta,direction,output_direction)["output"]
	base.rotation.y = - output_direction.angle()
	
	if base.rotation.y > 1 or base.rotation.y < -1:
		desired_state = max(DesiredState.MUST_RESTEP,desired_state)

func extend_arms(delta:float) -> void:
	var intermediate_tg = IK_variables["intermediate_tg"]
	output_intermediate_target = extension_second_order.vec2_second_order_response(
			delta,intermediate_tg,output_intermediate_target)["output"]
	var middle_angle:float = get_middle_angle(segment_1.segment_length,segment_2.segment_length,output_intermediate_target)
	var base_angle:float = get_base_angle(segment_1.segment_length,segment_2.segment_length,middle_angle,output_intermediate_target)
	segment_3.rotation.x = incidence_angle - middle_angle - base_angle
	segment_2.rotation.x = middle_angle
	segment_1.rotation.x = base_angle
	
	if middle_angle == 0:
		desired_state = DesiredState.MUST_RESTEP
	elif middle_angle < PI/6:
		desired_state = DesiredState.NEEDS_RESTEP

func get_middle_angle(L2:float,L1:float,target:Vector2) -> float:
	var a:float = 2*PI
	var b:float = -1
	if elbow_up: 
		a = 0
		b = 1
	var x:float = target.x
	var y:float = target.y
	return a + b *  acos((x**2+y**2-L1**2-L2**2) /(2*L1*L2) )

func get_base_angle(L1:float,L2:float,middle_angle:float,target:Vector2) -> float:
	var x:float = target.x
	var y:float = target.y
	return atan(y/x) - atan(L2*sin(middle_angle)/ (L1+L2*cos(middle_angle)) )

func update_returning_status() -> void:
	if is_returning:
		var max_horizontal_length = get_max_horizontal_length()
		var current_horizontal_length = get_horizontal_length()
		var length_ratio:float = max(0,1 - current_horizontal_length/max_horizontal_length)
		update_returning_phase(length_ratio)
		check_dist_to_rest()

func update_returning_phase(length_ratio:float) -> void:
	if length_ratio <.1:
		returning_phase = ReturningPhase.LIFTING
	elif length_ratio <.85:
		returning_phase = ReturningPhase.MID_SWING
	else:
		returning_phase = ReturningPhase.BACK_SWING

func check_dist_to_rest() -> void:
	var end_pos:Vector3 = to_local(segment_3.segment_end.global_position)
	var dist_to_rest:float = end_pos.distance_squared_to(rest_pos)
	if dist_to_rest < .0001: # is_equal_approx to sensible
		is_returning = false
		draw_multi_line(path_array,path_mesh)
		path_array.clear()


#region editor walk simulation 
func emulate_target_position(delta:float) -> Vector3:
	var target_pos:Vector3 = target_marker.position
	if is_returning:
		target_pos = get_returning_position(delta,target_marker.position)
	else:
		var dir:Vector3 = target_marker.position.direction_to(simulation_target+Vector3(0,rest_pos.y,0))
		target_pos =  target_marker.position + dir * delta * extension_speed
		check_end_ground_phase()
	return target_pos

func check_end_ground_phase() -> void:
	var intermediate_target3D:Vector3 =  get_intermediate_target3D(
				IK_variables["top_down_tg"],IK_variables["intermediate_tg"])
	var start_pos:Vector3 = ( to_local(segment_1.global_position) - 
			leg_offset.rotated(Vector3.UP,base.rotation.y) )
	
	var target_diff:Vector3 = intermediate_target3D - start_pos
	var max_diff:float = segment_1.segment_length + segment_2.segment_length
	var dist_too_large:bool = target_diff.length() > max_diff
		
	var horizontal_target_diff:float = Vector2(start_pos.x,start_pos.z).distance_squared_to(
				Vector2(intermediate_target3D.x,intermediate_target3D.z))
	var dist_too_low: bool = horizontal_target_diff < .1
	dist_too_low = false
	if dist_too_large or dist_too_low:
		is_returning = true
		walk_simulation = true


func draw_multi_line(line_points:Array[Vector3],old_mesh:MeshInstance3D) -> MeshInstance3D:
	if not line_points.size() > 0:
		return old_mesh
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	old_mesh.mesh = immediate_mesh
	old_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(line_points[0])
	for i in range(1,line_points.size()-1):
		immediate_mesh.surface_add_vertex(line_points[i])
		immediate_mesh.surface_add_vertex(line_points[i])
	immediate_mesh.surface_add_vertex(line_points[-1])
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	return old_mesh
#endregion

func get_returning_position(delta:float,target_pos:Vector3,) -> Vector3:
	desired_state = DesiredState.RETURNING
	var target_pos2D:Vector2 = Vector2(target_pos.x,target_pos.z)
	var rest_pos2D:Vector2 = Vector2(rest_pos.x,rest_pos.z)
	var dir:Vector2 = target_pos2D.direction_to(rest_pos2D)
	var dist_sqrd:float = target_pos2D.distance_squared_to(rest_pos2D)
	var move_effect:Vector2 = dir * delta * extension_speed
	
	if move_effect.length()**2 > dist_sqrd:
		target_pos2D = rest_pos2D
	else: target_pos2D += move_effect

	target_pos = Vector3(target_pos2D.x,get_returning_height(),target_pos2D.y)
	return target_pos

func get_rest_pos() -> Vector3:
	if is_returning: return rest_pos
	
	var rest_position = (Vector3(rest_distance,0,0) -
			 (movement_dir * move_direction_impact).rotated(Vector3(0,1,0),-rotation.y))
	
	#var diff = rest_position - rest_pos
	#if  is_returning and diff.length_squared() > 1 : #don't update on return
		#return rest_pos
	
	var max_length:float = segment_1.segment_length  + segment_2.segment_length + segment_3.segment_length
	var query_limit:Vector3 = rest_position + Vector3(0,-max_length,0)
	var query:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(to_global(rest_position),to_global(query_limit))
	query.collide_with_areas = true
	var result:Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	
	if not result.is_empty():
		rest_position = to_local(result["position"])
	else:
		rest_position.y = -leg_height - position.y

	return rest_position

func get_returning_height() -> float:
	var max_horizontal_length = get_max_horizontal_length()
	var current_horizontal_length = get_horizontal_length()
	var length_ratio:float = max(0,1 - current_horizontal_length/max_horizontal_length)
	var estimate_height:float = lerp(last_extended_position.y,rest_pos.y,length_ratio)
	var additional_height:float = returning_trajectory.sample(length_ratio)
	additional_height = additional_height * max_horizontal_length
	return estimate_height + additional_height

func get_max_horizontal_length() -> float:
	return Vector2(last_extended_position.x,last_extended_position.z).distance_to(
		Vector2(rest_pos.x,rest_pos.z))

func get_horizontal_length() -> float:
	var dist = Vector2(target_marker.position.x,target_marker.position.z)-(
		Vector2(rest_pos.x,rest_pos.z))
	return dist.length()

func get_intermediate_target(L3:float, plane_target:Vector2) -> Vector2:
	plane_target.x -= L3 * cos(incidence_angle)
	plane_target.y -= L3 * sin(incidence_angle) 
	return plane_target

func get_intermediate_target3D(top_down_target:Vector2,intermediate_tg:Vector2) -> Vector3:
	var intermediate_top_down:Vector2 = top_down_target.normalized()*intermediate_tg.x
	return Vector3(intermediate_top_down.x,
			 -intermediate_tg.y, intermediate_top_down.y)

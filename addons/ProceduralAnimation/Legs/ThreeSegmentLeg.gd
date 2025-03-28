@tool
@icon("res://addons/ProceduralAnimation/Legs/ThreeSegmentLeg.png")
extends Node3D
class_name ThreeSegmentLegClass

## [color=red]Warning:[/color] Do not use by itself.
## [br] This class is used by ThreeSegmentLeg

const MARKER:PackedScene = preload("res://addons/ProceduralAnimation/marker.tscn")

@export_group("Simulation details")
## Activates a walk cycle simulation.
@export var _walk_simulation:bool = false
var _simulation_target:Vector3 = Vector3(10,0,0)
## Controls the rotation angle of the leg (in radians).
@export_range(-PI,PI,.01) var _simulation_rotation:float = 0:
	set(new_value):
		_simulation_rotation = new_value
		_simulation_target.x = 10 * cos(_simulation_rotation)
		_simulation_target.z = 10 * sin(_simulation_rotation)
		var current_target_dist:float = Vector2(target_marker.position.x,target_marker.position.z).length()
		target_marker.position.x = current_target_dist * cos(_simulation_rotation)
		target_marker.position.z = current_target_dist * sin(_simulation_rotation)

#region Leg configuration exports
@export_group("Segment configuration")
@export_subgroup(("Base"))
## Controls the length of the segment (along the x axis).
@export_range(0,5,.01,"or_greater") var base_length:float=.5:
	set(new_value):
		base_length = new_value
		if not base: return
		base.segment_length = new_value
		base.position.x = -base.segment_length/2
		segment_1.position.z = leg_horizontal_offset + base.segment_length/2 # (z not x because rotated PI/2)
		base.update()
## Controls the offset of the segment (along the y axis).
@export var leg_vertical_offset:float = 0:
	set(new_value):
		leg_vertical_offset = new_value
		leg_offset.y = new_value
## Controls the offset of the segment (along the x axis).
@export var leg_horizontal_offset:float = 0:
	set(new_value):
		leg_horizontal_offset = new_value
		leg_offset.z = new_value # (z not x because rotated PI/2)
var leg_offset:Vector3 = Vector3.ZERO:
	set(new_value):
		leg_offset = new_value
		if not segment_1: return
		segment_1.position = leg_offset
		segment_1.position.z += base.segment_length/2

@export_subgroup("Segment 1")
## Controls the length of the segment (along the x axis).
@export_range(0,5,.01,"or_greater") var segment_1_length:float=1.5:
	set(new_value):
		segment_1_length = new_value
		if not segment_1: return
		segment_1.segment_length = new_value
		segment_2.position.z = segment_1.segment_length # (z not x because rotated PI/2)
		segment_1.update()
@export_subgroup("Segment 2")
## Controls the length of the segment (along the x axis).
@export_range(0,5,.01,"or_greater") var segment_2_length:float=1.5:
	set(new_value):
		segment_2_length = new_value
		if not segment_2: return
		segment_2.segment_length = new_value
		segment_3.position.z = segment_2.segment_length # (z not x because rotated PI/2)
		segment_2.update()
@export_subgroup("Segment 3")
## Controls the length of the segment (along the x axis).
@export_range(0,5,.01,"or_greater") var segment_3_length:float=1:
	set(new_value):
		segment_3_length = new_value
		if not segment_3: return
		segment_3.segment_length = new_value
		segment_3.update()
#endregion


#region Leg behavior exports
@export_group("Leg behavior")
## Distance of the resting position from the leg base.
@export var rest_distance:float = 2
## Distance (squared) to the target before the leg considers it's on ground
## If the leg seems to be stuck on resting position, increase the threshold
@export_range(.001,1,.001,"exp") var target_sensibility_treshold:float =.001
## Trajectory followed by the leg when returning to the resting position.
@export var _returning_trajectory:Curve
## Specifies the elbow configuration (up or down).
@export var elbow_up:bool = true
## Incidence angle of the third segment relative to the ground (in radians).
@export_range(0,PI,.01) var incidence_angle:float = PI/2
## Controls the speed of leg's extension/retraction.
@export var extension_speed:float = 2
## body direction impact on rest positions.
@export_range(0,2) var move_direction_impact:float = 1
## Leg rotation amplitude (in radians).
## [br]Defines the maximum angular displacement of the leg from its rest position.
## [br][b]Example:[/b] For rotation_amplitude = 2*PI/4, the leg can rotate up to a quarter turn (±45°) in both directions.
@export_range(0,2*PI,.001) var rotation_amplitude:float = 3*PI/2
## Defines the minimum distance distance autorized between the leg base and the foot.
## [br][b]Note:[/b] Distance processed in 2D (x,z).
@export_range(0,1,.001) var min_dist_to_base: float = .2

@export_subgroup("Rotation second order")
## Configuration weights for rotation second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation.
@export var _rota_second_order_config:Dictionary:
	set(new_value):
		_rota_second_order_config = new_value
		_rota_second_order = SecondOrderSystem.new(_rota_second_order_config)
## Second order controller
@export var _rota_second_order:SecondOrderSystem
var _output_direction:Vector2

@export_subgroup("Extension second order")
## Configuration weights for extension second order controller.
## [br]See [b]SecondOrderSystem[/b] documentation
@export var _extension_second_order_config:Dictionary:
	set(new_value):
		_extension_second_order_config = new_value
		_extension_second_order = SecondOrderSystem.new(_extension_second_order_config)
## Second order controller
@export var _extension_second_order:SecondOrderSystem
#endregion


#region Marker exports
@export_group("Markers")
## Displays markers at the beginning of each segment.
@export var _show_begin_segment_markers:bool = true
## Defines the color of the markers at the beginning of each segment.
@export_color_no_alpha var _begin_markers_color:Color = Color.BLACK
## Displays markers at the end of each segment.
@export var _show_end_segment_markers:bool = true
## Defines the color of the markers at the end of each segment.
@export_color_no_alpha var _end_markers_color:Color = Color.RED
## Display marker at the resting position.
@export var _show_rest_pos_marker:bool = true
## Defines the color of the marker at the resting position.
@export_color_no_alpha var _rest_pos_marker_color:Color = Color.GREEN
## Display marker at the targeted position.
@export var _show_target_pos_marker:bool = true
## Defines the color of the markers at the targeted position.
@export_color_no_alpha var _target_pos_marker_color:Color = Color.BLUE
@export var _show_path:bool = true
var _path_array:Array[Vector3]
var _path_mesh:MeshInstance3D
#endregion


#region Process variables
## target for segmetns 1 and 2 for IK
var _output_intermediate_target:Vector2
##last position at max extension (use for returning path)
var _last_extended_position:Vector3 = Vector3.ZERO
## resting position
var rest_pos:Vector3
## dictionnary of format {"top_down_tg":top_down_tg,"direction":direction,"intermediate_tg":intermediate_tg}
var IK_variables:Dictionary
## true if leg is returning to resting position
var is_returning:bool = false:
	set(new_value):
		if new_value and not is_returning:
			var next_extended_position:Vector3 = to_local(segment_3.segment_end.global_position)
			if abs(next_extended_position) - abs(rest_pos) > Vector3.ZERO:
				_last_extended_position = next_extended_position
		is_returning = new_value
		if is_returning: _target_pos_marker_color = Color.YELLOW
		else: _target_pos_marker_color = Color.BLUE
## movement direction of the body
var movement_dir:Vector3
## used for more precise gait rules
enum DesiredState {OK_ON_GROUND,NEEDS_RESTEP,MUST_RESTEP,RETURNING}
var desired_state:int = DesiredState.OK_ON_GROUND
## Position of the foot in the world, used to anchor the feet in position
var global_current_ground_pos:Vector3
## color=red]Warning:[/color] Not implemented yet, will be used for gravity implementation
var is_foot_on_ground:bool = true

#endregion

## leg's element
var base: LegSegment
var segment_1: LegSegment
var segment_2: LegSegment
var segment_3: LegSegment
var target_marker: Marker3D
var _marker_childs:Array[Node3D] #can't delete all childs so keep count
#region Setup
## initiate leg for game runtime
func _ready() -> void:
	_get_nodes()
	_update_segment_lengths()
	rest_pos = get_rest_pos()
	global_current_ground_pos = to_global(rest_pos)
	_output_intermediate_target = Vector2.ZERO
	_output_direction = Vector2.ZERO
	_rota_second_order = SecondOrderSystem.new(_rota_second_order_config)
	_extension_second_order = SecondOrderSystem.new(_extension_second_order_config)


func _get_nodes() -> void:
	base = $Base
	target_marker = $Editor_target
	segment_1 = $Base/Segment_1
	segment_2 = $Base/Segment_1/Segment_2
	segment_3 = $Base/Segment_1/Segment_2/Segment_3

## intiate leg for editor runtime
func _initate_editor() -> void:
	_get_nodes()
	_update_segment_lengths()
	_output_intermediate_target = Vector2.ZERO
	_output_direction = Vector2.ZERO
	_rota_second_order = SecondOrderSystem.new(_rota_second_order_config)
	_extension_second_order = SecondOrderSystem.new(_extension_second_order_config)
	_path_mesh = MeshInstance3D.new()
	add_child(_path_mesh)


func _update_segment_lengths() -> void:
	base_length = base_length
	leg_horizontal_offset = leg_horizontal_offset
	leg_vertical_offset = leg_vertical_offset
	segment_1_length = segment_1_length
	segment_2_length = segment_2_length
	segment_3_length = segment_3_length

## update markers (called only in editor)
func _set_markers() -> void:
	var segments:Array = [segment_1,segment_2,segment_3]
	for segment:LegSegment in segments:
		segment.show_begin_marker = _show_begin_segment_markers
		segment.show_end_marker = _show_end_segment_markers
		segment.begin_marker_color = _begin_markers_color
		segment.end_marker_color = _end_markers_color
		segment.update()
	if _show_rest_pos_marker:
		var marker:Node3D = _add_marker(_rest_pos_marker_color)
		marker.position = rest_pos
	if _show_target_pos_marker:
		var marker:Node3D = _add_marker(_target_pos_marker_color)
		marker.position = target_marker.position

func _add_marker(color:Color) -> Node3D:
	var marker:Node3D = MARKER.instantiate()
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	for mesh:MeshInstance3D in marker.get_children():
		mesh.set_surface_override_material(0,material)
	add_child(marker)
	_marker_childs.append(marker)
	return marker
#endregion


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		for child:Node in _marker_childs:
			child.queue_free()
		_marker_childs.clear()
		if not _path_mesh:
			_initate_editor()
	_move_leg(delta)


#region Move to target
func _move_leg(delta:float) -> void:
	desired_state = DesiredState.OK_ON_GROUND
	if Engine.is_editor_hint():
		_set_markers()
		if _walk_simulation:
			target_marker.global_position = _emulate_target_position(delta)
		if _show_path:
			_path_array.append(to_local(segment_3.segment_end.global_position))
	# target_marker.global_position moved by legcontroller
	IK_variables =  _get_IK_variables(target_marker.global_position)
	_rotate_base(delta)
	_extend_leg(delta)


## rotate leg towards target
func _rotate_base(delta:float) -> void:
	if is_returning: #second order only if not on ground
		@warning_ignore("unsafe_call_argument")
		_output_direction = _rota_second_order.vec2_second_order_response(
				delta,IK_variables["direction"],_output_direction)["output"]
		base.rotation.y = - _output_direction.angle() + PI/2
	else:
		@warning_ignore("unsafe_method_access")
		base.rotation.y = - IK_variables["direction"].angle() + PI/2
		_output_direction = IK_variables["direction"]
	if base.rotation.y > rotation_amplitude*.5 + PI/2 or base.rotation.y < -rotation_amplitude*.5 + PI/2:
		print("angle worng")
		desired_state = max(DesiredState.MUST_RESTEP,desired_state)
	base.position.x = -base.segment_length/2*cos(base.rotation.y - PI/2)
	base.position.z = +base.segment_length/2*sin(base.rotation.y- PI/2)

## extend leg to target (in a plane)
func _extend_leg(delta:float) -> void:
	if is_returning:#second order only if not on ground
		@warning_ignore("unsafe_call_argument")
		_output_intermediate_target = _extension_second_order.vec2_second_order_response(
				delta,IK_variables["intermediate_tg"],_output_intermediate_target)["output"]
	else:
		_output_intermediate_target = IK_variables["intermediate_tg"]
	var middle_angle:float = _get_middle_angle(segment_1.segment_length,segment_2.segment_length,_output_intermediate_target)
	var base_angle:float = get_base_angle(segment_1.segment_length,segment_2.segment_length,middle_angle,_output_intermediate_target)
	segment_3.rotation.x = incidence_angle - middle_angle - base_angle
	segment_2.rotation.x = middle_angle
	segment_1.rotation.x = base_angle

	if middle_angle == 0: #if extend maximum
		desired_state = DesiredState.MUST_RESTEP
	elif middle_angle < PI/6:
		desired_state = DesiredState.NEEDS_RESTEP

## get angle of second segment
func _get_middle_angle(L2:float,L1:float,target:Vector2) -> float:
	var a:float = 2*PI
	var b:float = -1
	if elbow_up:
		a = 0
		b = 1
	var x:float = target.x
	var y:float = target.y
	return a + b *  acos((x**2+y**2-L1**2-L2**2) /(2*L1*L2) )

## get angle of first segment
func get_base_angle(L1:float,L2:float,middle_angle:float,target:Vector2) -> float:
	var x:float = target.x
	var y:float = target.y
	@warning_ignore("unsafe_call_argument")
	return atan(y/x) - atan(L2*sin(middle_angle)/ max(.00001,(L1+L2*cos(middle_angle))) )
#endregion


#region Update leg returning state
func is_return_phase_finished() ->bool:
	var dist_to_rest:float
	if _walk_simulation:
		dist_to_rest = target_marker.position.distance_squared_to(rest_pos)
	else:
		var end_pos2D:Vector2 = Vector2(target_marker.position.x,target_marker.position.z)
		var rest_pos_2D:Vector2 = Vector2(rest_pos.x,rest_pos.z)
		dist_to_rest = end_pos2D.distance_squared_to(rest_pos_2D)
	return dist_to_rest < target_sensibility_treshold # is_equal_approx to sensible
#endregion


#region Editor walk simulation
func _emulate_target_position(delta:float) -> Vector3:
	var target_pos:Vector3 = target_marker.position
	if is_returning:
		rest_pos = get_rest_pos()
		target_pos = get_returning_position(delta,target_pos)
	else:
		var dir:Vector3 = target_pos.direction_to(_simulation_target+Vector3(0,rest_pos.y,0))
		target_pos =  target_pos + dir * delta * extension_speed
		_check_end_ground_phase()
	return to_global(target_pos)

## update is_returning
func _check_end_ground_phase() -> void:
	@warning_ignore("unsafe_call_argument")
	var intermediate_target3D:Vector3 =  _get_intermediate_target3D(
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

## draw trajectory (used for walk simulation path)
func _draw_multi_line(line_points:Array[Vector3],old_mesh:MeshInstance3D) -> MeshInstance3D:
	if not line_points.size() > 0:
		return old_mesh
	var immediate_mesh:ImmediateMesh = ImmediateMesh.new()
	var material:ORMMaterial3D = ORMMaterial3D.new()

	old_mesh.mesh = immediate_mesh
	old_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(line_points[0])
	for i:int in range(1,line_points.size()-1):
		immediate_mesh.surface_add_vertex(line_points[i])
		immediate_mesh.surface_add_vertex(line_points[i])
	immediate_mesh.surface_add_vertex(line_points[-1])
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	return old_mesh
#endregion


#region State variables getters
## get resting position
func get_rest_pos() -> Vector3:
	var base_offset:Vector3 = Vector3.ZERO#leg_offset.rotated(Vector3.UP,base.rotation.y )
	var dir_offset:Vector3 = (movement_dir * move_direction_impact).rotated(Vector3(0,1,0),-global_rotation.y)
	var default_pos:Vector3 = (Vector3(rest_distance,0,0)
			+ Vector3(base_offset.x,0,base_offset.z) + dir_offset)
	var max_length:float = segment_1.segment_length  + segment_2.segment_length + segment_3.segment_length
	var query_start = default_pos + Vector3(0,max_length/3,0)

	#var debug = _add_marker(Color.SPRING_GREEN)
	#debug.global_position = to_global(query_start)

	var potential_rest_pos:Array = []
	var limit:Vector3 = default_pos + Vector3(0,-max_length,0)
	var new_pos = cast_ray(query_start, limit)
	if new_pos:
		potential_rest_pos.append(new_pos)

	var rotations: Array = [
		Vector3(0, 0, 1),
		#Vector3(0, 0, -1), #not used because often just under hip
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0) ]
	for rotation_axis:Vector3 in rotations:
		limit = default_pos + Vector3(0, -max_length, 0).rotated(rotation_axis, PI/8)
		new_pos = cast_ray(query_start, limit)
		if new_pos:
			potential_rest_pos.append(new_pos)

	var rest_position = get_best_suitable_position(potential_rest_pos,default_pos)
	#var debug2 = _add_marker(Color.BLUE)
	#debug2.global_position = to_global(default_pos)
	#var debug3 = _add_marker(Color.GREEN)
	#debug3.global_position = to_global(rest_position)
	return rest_position

## returns the best resting position among an array of candidate.
func get_best_suitable_position(potential_rest_pos,default_pos) -> Vector3:
	var best_pos:Vector3 = default_pos
	var start_pos:Vector3 = to_local(base.global_position)
	var min_dist:float = +INF
	for pos:Vector3 in potential_rest_pos:

		var max_leg_range:float = (leg_horizontal_offset + segment_1.segment_length
				+ segment_2.segment_length
				+ segment_3.segment_length * sin(incidence_angle) )
		if max_leg_range < base.position.distance_to(pos): continue  #ignores position to far from hip
		var pos_2D:Vector2 = Vector2(pos.x,pos.z)
		var diff:Vector2 = (pos_2D-Vector2(start_pos.x,start_pos.z))
		if diff < Vector2.ONE * min_dist_to_base: continue  #ignores position to close to hip

		var dist:float = pos.distance_squared_to(default_pos)
		if dist < min_dist :
			min_dist = dist
			best_pos = pos
	return best_pos


func cast_ray(query_start,query_limit):
	#var debug = _add_marker(Color.YELLOW)
	#debug.global_position = to_global(query_limit)
	var query:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(to_global(query_start),to_global(query_limit))
	query.collide_with_areas = true
	var result:Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		#var debug2 = _add_marker(Color.CRIMSON)
		#debug2.global_position = to_global(to_local(result["position"]))
		return to_local(result["position"])

## get next target pos of returning legs
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
	target_pos = Vector3(target_pos2D.x,_get_returning_height(),target_pos2D.y)
	return target_pos

## get target height of returning legs
func _get_returning_height() -> float:
	var max_horizontal_length:float = _get_max_horizontal_length()
	var current_horizontal_length:float = _get_horizontal_length()
	var length_ratio:float = max(0,1 - current_horizontal_length/max_horizontal_length)
	var estimate_height:float = lerp(_last_extended_position.y,rest_pos.y,length_ratio)
	var additional_height:float = _returning_trajectory.sample(length_ratio)
	additional_height = additional_height * max_horizontal_length
	return estimate_height + additional_height

## get leg horizontal length on last max extended position
func _get_max_horizontal_length() -> float:
	return Vector2(_last_extended_position.x,_last_extended_position.z).distance_to(
		Vector2(rest_pos.x,rest_pos.z))

## get current horitontal length
func _get_horizontal_length() -> float:
	var dist:Vector2 = Vector2(target_marker.position.x,target_marker.position.z)-(
		Vector2(rest_pos.x,rest_pos.z))
	return dist.length()

## process intermediate variable used for IK
func _get_IK_variables(target:Vector3) -> Dictionary:
	target = to_local(target)
	var start_pos:Vector3 = to_local(base.global_position)
	var top_down_tg:Vector2 = Vector2(target.x,target.z)
	var direction:Vector2 = Vector2(start_pos.x,start_pos.z).direction_to(top_down_tg)

	target -= leg_offset.rotated(Vector3.UP,base.rotation.y)
	top_down_tg = Vector2(target.x,target.z)

	var diff:Vector2 = (top_down_tg-Vector2(start_pos.x,start_pos.z))

	if diff < Vector2.ZERO:
		desired_state = max(DesiredState.MUST_RESTEP,desired_state)
	elif diff < Vector2.ONE * min_dist_to_base:
		desired_state = max(DesiredState.NEEDS_RESTEP,desired_state)

	var side_view_tg:Vector2 = Vector2(top_down_tg.length(),-target.y)
	var intermediate_tg:Vector2 = _get_intermediate_target(segment_3.segment_length,side_view_tg)
	return {"top_down_tg":top_down_tg,"direction":direction,"intermediate_tg":intermediate_tg}

## get target used for segment 1 and 2 (in side view plane)
func _get_intermediate_target(L3:float, plane_target:Vector2) -> Vector2:
	plane_target.x -= L3 * cos(incidence_angle)
	plane_target.y -= L3 * sin(incidence_angle)
	return plane_target

## get target used for segment 1 and 2 (in 3D)
func _get_intermediate_target3D(top_down_target:Vector2,intermediate_tg:Vector2) -> Vector3:
	var intermediate_top_down:Vector2 = top_down_target.normalized()*intermediate_tg.x
	return Vector3(intermediate_top_down.x,
			 -intermediate_tg.y, intermediate_top_down.y)
#endregion


@tool
extends Node3D
class_name LegSegment


const MARKER = preload("res://marker.tscn")
## Controls the length of the segment (along the z axis).
@export_range(0,5,.01,"or_greater") var segment_length:float=1:
	set(new_value):
		segment_length = new_value
		update()
## Controls the width of the segment (along the x axis).
@export_range(0,5,.01,"or_greater") var segment_width:float=.4:
	set(new_value):
		segment_width = new_value
		update()
## Controls the height of the segment (along the y axis).
@export_range(0,5,.01,"or_greater") var segment_height:float=.2:
	set(new_value):
		segment_height = new_value
		update()

var show_begin_marker:bool = false
var begin_marker_color:Color
var show_end_marker:bool = false
var end_marker_color:Color

var segment_end: Node3D
var segment_begin:Node3D
var segment_shape: CSGBox3D
var delete_childs:Array[Node3D] #can't delete all childs so keep count

func update():
	for child in delete_childs:
		child.queue_free()
	delete_childs.clear()
	segment_begin = add_marker(begin_marker_color)
	segment_end = add_marker(end_marker_color)
	if not show_begin_marker: segment_begin.visible = false
	if not show_end_marker: segment_end.visible = false
	add_segment_shape()
	segment_shape.size.x = segment_width
	segment_shape.size.y = segment_height
	update_length()

func add_marker(color:Color) -> Node3D:
	var marker:Node3D = MARKER.instantiate()
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	for mesh:MeshInstance3D in marker.get_children():
		mesh.set_surface_override_material(0,material)
	add_child(marker)
	delete_childs.append(marker)
	return marker

func add_segment_shape() -> void:
	segment_shape = CSGBox3D.new()
	add_child(segment_shape)
	delete_childs.append(segment_shape)

func update_length() -> void:
	segment_begin.position = Vector3.ZERO
	segment_end.position.z = segment_length
	segment_shape.size.z = segment_length
	segment_shape.position.z = segment_length/2

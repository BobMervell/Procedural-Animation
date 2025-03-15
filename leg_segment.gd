@tool
extends Node3D
class_name LegSegment


const MARKER:PackedScene = preload("res://marker.tscn")
## Controls the length of the segment (along the z axis).
var segment_length:float=1:
	set(new_value):
		segment_length = new_value
		update()
## Controls the width of the segment (along the x axis).
var _segment_width:float=.4:
	set(new_value):
		_segment_width = new_value
		update()
## Controls the height of the segment (along the y axis).
var _segment_height:float=.2:
	set(new_value):
		_segment_height = new_value
		update()

var show_begin_marker:bool = false
var begin_marker_color:Color
var show_end_marker:bool = false
var end_marker_color:Color

var segment_end:Node3D
var segment_begin:Node3D
var _segment_shape:CSGBox3D
var _delete_childs:Array[Node3D] #can't delete all childs so keep count

func _ready() -> void:
	update()

func update() -> void:
	for child:Node in _delete_childs:
		child.queue_free()
	_delete_childs.clear()
	segment_begin = _add_marker(begin_marker_color)
	segment_end = _add_marker(end_marker_color)
	if not show_begin_marker: segment_begin.visible = false
	if not show_end_marker: segment_end.visible = false
	_add__segment_shape()
	_segment_shape.size.x = _segment_width
	_segment_shape.size.y = _segment_height
	_update_length()

func _add_marker(color:Color) -> Node3D:
	var marker:Node3D = MARKER.instantiate()
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	for mesh:MeshInstance3D in marker.get_children():
		mesh.set_surface_override_material(0,material)
	add_child(marker)
	_delete_childs.append(marker)
	return marker

func _add__segment_shape() -> void:
	_segment_shape = CSGBox3D.new()
	add_child(_segment_shape)
	_delete_childs.append(_segment_shape)

func _update_length() -> void:
	segment_begin.position = Vector3.ZERO
	segment_end.position.z = segment_length
	_segment_shape.size.z = segment_length
	_segment_shape.position.z = segment_length/2

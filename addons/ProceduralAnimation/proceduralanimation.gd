@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("ThreeSegmentLeg","Node3D",preload("res://addons/ProceduralAnimation/Legs/LegInstantiater.gd"),
		preload("res://addons/ProceduralAnimation/Legs/ThreeSegmentLeg.png"))
	add_custom_type("RadialQuadripedController","Node3D",preload("res://addons/ProceduralAnimation/BodiesController/RadialQuadripedController.gd"),
		preload("res://addons/ProceduralAnimation/BodiesController/radial_quadriped_icon.png"))

func _exit_tree():
	remove_custom_type("RadialQuadripedController")
	remove_custom_type("ThreeSegmentLeg")


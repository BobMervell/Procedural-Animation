@tool
extends Node


func _init() -> void:
	if name:
		var root = EditorInterface.get_edited_scene_root()
		var folder_path:String = get_script().resource_path.get_base_dir() + "/"
		var scene = load(folder_path + name + ".tscn")
		var instance = scene.instantiate()
		root.add_child(instance)
		instance.set_owner(root)
		self.queue_free()

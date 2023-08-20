extends "res://Floppy3D.gd"

func _ready():
	playerbody = scene_root.get_camera().get_parent().get_parent()
	$FloppyMesh.mesh = load("res://floppy_2_mesh.tres")

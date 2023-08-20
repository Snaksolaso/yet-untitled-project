class_name Floppy1 extends "res://Floppy3D.gd"

func focus():
	focused = true
	$Viewport/Spatial/Player/KinematicBody.paused = false

func unfocus():
	$Viewport/Spatial/Player/KinematicBody.paused = true
	focused = false
	emit_signal("unfocus")

func _ready():
	$FloppyMesh.mesh = load("res://floppy_1_mesh.tres")

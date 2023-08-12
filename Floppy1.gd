class_name Floppy1 extends FloppyDisk

onready var child_player = $Viewport/Spatial/Player/KinematicBody

func focus():
	focused = true
	$Viewport/Spatial/Player/KinematicBody.paused = false

func unfocus():
	$Viewport/Spatial/Player/KinematicBody.paused = true
	focused = false
	emit_signal("unfocus")

# fix later :/ really hacky
func _unhandled_input(event):
	if not focused:
		return
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("rotate_object"):
			if event.relative.x > 0:
				child_player.hand.rotate_y(-lerp(0, child_player.spin, event.relative.x/10))
			elif event.relative.x < 0:
				child_player.hand.rotate_y(-lerp(0, child_player.spin, event.relative.x/10))
			if event.relative.y > 0:
				child_player.hand.rotate_x(-lerp(0, child_player.spin, event.relative.y/10))
			elif event.relative.y < 0:
				child_player.hand.rotate_x(-lerp(0, child_player.spin, event.relative.y/10))
		else:
			child_player.time_iterators.flashlight_catchup = child_player.flashlight_starting_time
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if event.relative.x > 0:
				child_player.rotate_y(-lerp(0, child_player.spin, event.relative.x/10))
			elif event.relative.x < 0:
				child_player.rotate_y(-lerp(0, child_player.spin, event.relative.x/10))
			if event.relative.y > 0 && child_player.camera.rotation.x >= -PI/2:
				child_player.camera.rotate_x(-lerp(0, child_player.spin, event.relative.y/10))
			elif event.relative.y < 0 && child_player.camera.rotation.x <= PI/2:
				child_player.camera.rotate_x(-lerp(0, child_player.spin, event.relative.y/10))

func _ready():
	if child_scene:
		pause_mode = Node.PAUSE_MODE_PROCESS
	$FloppyMesh.mesh = load("res://floppy_1_mesh.tres")

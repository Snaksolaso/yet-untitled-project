class_name UIFloppy extends FloppyDisk

func _unhandled_input(event):
	if not focused:
		return
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.relative.x > 0:
			pass
		elif event.relative.x < 0:
			pass
		if event.relative.y > 0:
			pass
		elif event.relative.y < 0:
			pass

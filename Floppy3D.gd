extends FloppyDisk

onready var scene_root = $Viewport
var playerbody = null
# Called when the node enters the scene tree for the first time.

func focus():
	focused = true
	playerbody.unpause()
	print(playerbody)

func unfocus():
	focused = false
	playerbody.pause()

func _ready():
	playerbody = scene_root.get_camera().get_parent().get_parent()

func _unhandled_input(event):
	if not playerbody.paused:
		playerbody.process_input(event)


extends Spatial

export var child_scene = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$KinematicBody.child_scene = child_scene
	if child_scene:
		$KinematicBody.paused = true
		$KinematicBody.pause_mode = Node.PAUSE_MODE_PROCESS


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

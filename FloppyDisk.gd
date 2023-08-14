class_name FloppyDisk extends PhysicsEntityHoldable

signal eject
signal unfocus

onready var viewport = $Viewport
onready var sprite = $Viewport/AnimatedSprite

var loaded = false
var focused = false

func on_sprite_animation_finish():
	sprite.play("default")

func insert():
	sprite.play("Static")

func focus():
	focused = true

func unfocus():
	focused = false
	emit_signal("unfocus")

func get_viewport_path():
	return $Viewport.get_path()

func get_floppy_mesh():
	return $FloppyMesh.mesh

func _focused_process(delta):
	pass

func _process(delta):
	if not focused:
		return
	else:
		_focused_process(delta)

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	sprite.connect("animation_finished", self, "on_sprite_animation_finish")

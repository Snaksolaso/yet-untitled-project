extends Node2D

# mouse sensitivity
export var mouse_speed = 1

onready var mouse = $Mouse

func process_mouse_input(direction: Vector2):
	update_mouse(direction)

func update_mouse(direction: Vector2):
	mouse.position += (direction * mouse_speed).floor()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

extends KinematicBody

export var spin = 0.03
export var jump_velocity = 10

onready var camera = $CameraPivot/Camera

var speed = 80

var gravity = Vector3.UP * 30
var velocity = Vector3.ZERO
var ground = false
var paused = true
var jumping = false

func pause():
	paused = true

func unpause():
	paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _get_input(delta):
	var vy = velocity.y
	velocity -= Vector3(0, vy ,0)
	
	#jump calculations
	if Input.is_action_just_pressed("jump"):
		if ground:
			velocity.y += jump_velocity
			jumping = true
	
	# Directional input motion calculations
	if Input.is_action_pressed("move_forward"):
		if ground:
			velocity += -transform.basis.z * speed * delta
	if Input.is_action_pressed("move_back"):
		if ground:
			velocity += transform.basis.z * speed * delta
	if Input.is_action_pressed("strafe_right"):
		if ground:
			velocity += transform.basis.x * speed * delta
	if Input.is_action_pressed("strafe_left"):
		if ground:
			velocity += -transform.basis.x * speed * delta
	
	#friction calculations
	if ground:
		velocity *= 0.9
	else:
		velocity *= 0.99
	
	velocity += Vector3(0, vy ,0)

func _physics_process(delta):
	if not paused:
		if ground:
			if jumping:
				jumping = false
		else:
			velocity -= gravity * delta
		
		_get_input(delta)
		
		var snap = Vector3.DOWN if not (jumping or ground) else Vector3.ZERO
		if not jumping:
			velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(52), false)
		else:
			velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(52), false)
		ground = is_on_floor()
			

func process_input(event):
	if paused:
		return
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.relative.x > 0:
			rotate_y(-lerp(0, spin, event.relative.x/10))
		elif event.relative.x < 0:
			rotate_y(-lerp(0, spin, event.relative.x/10))
		if event.relative.y > 0 && camera.rotation.x >= -PI/2:
			camera.rotate_x(-lerp(0, spin, event.relative.y/10))
		elif event.relative.y < 0 && camera.rotation.x <= PI/2:
			camera.rotate_x(-lerp(0, spin, event.relative.y/10))

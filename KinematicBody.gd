# This script belongs to the physical body of the player. 
# It processes movement inputs, and also acts as an agent for the player wrt view culling and 
extends KinematicBody

onready var flashlight = get_node("../Flashlight")
onready var camera = get_node("CameraPivot/Camera")
onready var pivot = get_node("CameraPivot")
onready var collision = get_node("CollisionShape")
onready var headroom = get_node("RayCast")
onready var hud = get_node("../HUD")
onready var visibility_area = get_node("CameraPivot/Camera/VisibilityArea")
onready var held_object = null
onready var hand = get_node("CameraPivot/Camera/CarryArm/RigidBody/CollisionShape")
onready var arm = $CameraPivot/Camera/CarryArm

onready var picker = get_node("CameraPivot/Camera/Picker")

export var gravity = Vector3.DOWN * 20 # strength of gravity
export var walk_acceleration = 15

export var max_hold_length = 2
export var default_min_hold_length = 0.3
var min_hold_length = default_min_hold_length
export var sprint_acceleration = 20
export var air_acceleration = 2
export var crouchwalk_speed = 1
export var crouch_acceleration = 15
export var deceleration = 10
export var push = 0.5

export var walk_speed = 2.8 # maximum walk speed
export var sprint_speed = 7# maximum sprint speed

export var jump_speed = 6  # jump starting velocity

export var spin = 0.03  # effectively mouse sensitivity

export var default_flashlight_range = 70
export var raised_flashlight_range = 100

export var default_fov = 75
export var raised_fov = 40

export var max_health = 100

var paused  = false
var child_scene = false
var flashlight_starting_time = 1
var hp = max_health


var time_iterators = {"crouch": 1.0, "flashlight_focus": 1.0, "flashlight_catchup": 1.0 }
var iterator_factors = {"crouch": 7.0, "flashlight_focus": 5.0, "flashlight_catchup": 1.0 }

var velocity = Vector3.ZERO

var crouched = false
var stumped = false # true when player is unable to stand after releasing the crouch key. 
var jumping = false

# true when player is on ground
var ground = true

# true when flashlight is "raised" (right click zoomed)
var raised = false



static func lerp_angle(from, to, weight):
	return from + _short_angle_dist(from, to) * weight

static func _short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference


# get angle velocity (minus y) points from the camera and angle the bauble slightly towards that direction
func update_lean_pivot():
	var angle = (velocity - velocity.y).angle_to(-transform.basis.z)

func get_picked_area():
	return picker.get_collider()

func is_picking_area(area):
	return $CameraPivot/Camera/PickerArea.overlaps_area(area)

func update_flashlight():
	if paused:
		return
	if flashlight != null and camera != null:
		
		var raised = Input.is_action_pressed("focus_flashlight")
		if Input.is_action_just_pressed("focus_flashlight"):
			time_iterators.flashlight_focus = 1 - time_iterators.flashlight_focus
			time_iterators.flashlight_catchup = 1 - time_iterators.flashlight_catchup
		if Input.is_action_just_released("focus_flashlight"):
			time_iterators.flashlight_focus = 1 - time_iterators.flashlight_focus
			time_iterators.flashlight_catchup = 1 - time_iterators.flashlight_catchup
		
		# Modify various panrameters when the flashlight is focused.
		flashlight.spot_range = lerp((default_flashlight_range if raised else raised_flashlight_range),(raised_flashlight_range if raised else default_flashlight_range),time_iterators.flashlight_focus)
		flashlight.spot_angle = lerp((50 if raised else 28),(28 if raised else 50),time_iterators.flashlight_focus)
		camera.fov = lerp((default_fov if raised else raised_fov),(raised_fov if raised else default_fov),time_iterators.flashlight_focus)
		
		# It makes me nauseous for this value to be anything less than 1 unless It's zooming
		
		flashlight.rotation.x = lerp_angle(flashlight.rotation.x,camera.rotation.x, time_iterators.flashlight_catchup)
		flashlight.rotation.y = lerp_angle(flashlight.rotation.y, rotation.y, time_iterators.flashlight_catchup)
		flashlight.translation = translation + Vector3(0,0.551,0)

func get_status_string():
	var string = ""
	string += Time.get_time_string_from_system() + "\n"
	string += "Health: " + str(hp) + "\n"
	string += "Velocity: " + str(velocity) + "\n"
	string += "Ground: " + str(ground) + "\n"
	string += "Crouched: " + str(crouched) + "\n"
	string += "Stumped: " + str(stumped) + "\n"
	string += "Frametime: " + str(Performance.get_monitor(Performance.TIME_PROCESS)) + "\n"
	return string


# This is a monster of a function. At this point I'm scared to try and refactor it again. It works.

func get_input(delta):
	if paused:
		return
	# get rid of y velocity to make calculations easier
	var vy = velocity.y
	velocity.y = 0
	
	
	for index in get_slide_count():
		var collisioner := get_slide_collision(index)
		var body := collisioner.collider
		if body.get_class() == "RigidBody":
			#collisioner.collider.apply_central_impulse(-collisioner.normal * velocity * push)
			if body.global_translation.y < global_translation.y:
				var travel = collisioner.travel
				global_translation += Vector3(travel.x, -travel.y, travel.z) * delta
				velocity += collisioner.collider_velocity * delta * delta
				body.sleeping = true
			elif body.sleeping:
				body.sleeping = false
	
	var stopping = true
	var max_speed = walk_speed
	var a = walk_acceleration
	
	var delta_v = Vector3()
	
	# check if sprinting, change max speed and acceleration constant if so. 
	if Input.is_action_pressed("sprint"):
		max_speed = sprint_speed
		a = sprint_acceleration
	
	# Check if crouched
	if crouched:
		
		collision.scale = lerp(Vector3(1, 1, 1), Vector3(1, 0.4, 1), time_iterators.crouch)
		max_speed = crouchwalk_speed if ground else INF
		a = crouch_acceleration
	else:
		collision.scale = lerp(Vector3(1, 0.4, 1), Vector3(1, 1, 1), time_iterators.crouch)
	
	if not ground:
		stopping = false
		max_speed = INF
		a = air_acceleration
	
	
	var prior_velocity = velocity
	
	# Directional input motion calculations
	if Input.is_action_pressed("move_forward"):
		var opposing_component = velocity.project(transform.basis.z)
		if velocity.angle_to(-transform.basis.z) > PI/2:
			var amtsub = Vector3.ZERO
			if opposing_component.z > 0:
				amtsub = opposing_component * deceleration * delta
			velocity -= amtsub
			velocity += -transform.basis.z * amtsub.length()
		if ground:
			velocity -= velocity.project(transform.basis.x) * 3 * delta
		delta_v += -transform.basis.z * a * delta
		stopping = false
	if Input.is_action_pressed("move_back"):
		var opposing_component = velocity.project(-transform.basis.z)
		if velocity.angle_to(transform.basis.z) > PI/2:
			var amtsub = Vector3.ZERO
			if opposing_component.z > 0:
				amtsub = opposing_component * deceleration * delta
			velocity -= amtsub
		if ground:
			velocity -= velocity.project(transform.basis.x) * delta
		delta_v += transform.basis.z * a * delta
		stopping = false
	if Input.is_action_pressed("strafe_right"):
		var opposing_component = velocity.project(-transform.basis.x)
		if velocity.angle_to(transform.basis.x) > PI/2:
			var amtsub = Vector3.ZERO
			if opposing_component.x > 0:
				amtsub = opposing_component * deceleration * delta
			velocity -= amtsub
			velocity += transform.basis.x * amtsub.length()
		if ground:
			velocity -= velocity.project(transform.basis.z) * delta
		delta_v += transform.basis.x * a * delta
		stopping = false
	if Input.is_action_pressed("strafe_left"):
		var opposing_component = velocity.project(transform.basis.x)
		if velocity.angle_to(-transform.basis.x) > PI/2:
			var amtsub = Vector3.ZERO
			if opposing_component.x > 0:
				amtsub = opposing_component * deceleration * delta
			velocity -= amtsub
			velocity += -transform.basis.x * amtsub.length()
		if ground:
			velocity -= velocity.project(transform.basis.z) * delta
		delta_v += -transform.basis.x * a * delta
		stopping = false

	if stopping:
		velocity -= (delta * velocity.normalized()*15) if velocity.length() > 0.3 else velocity
		pass
	elif ground:
		velocity -= (delta * velocity.normalized()*10)
		pass
	else:
		velocity -= (delta * velocity.normalized())
		pass
	
	# This section is meant to prevent the player from increasing their speed indefinitely.
	# It checks whether the speed they would have after the game adds their walk/run speed
	# would be greater than their current maximum speed, and if so, does not add it.
	
	velocity += delta_v
	if velocity.length() > max_speed:
		velocity -= delta_v * 0.8
	
	velocity.y = vy
	#print(velocity)
	
	
	# jump input check
	if Input.is_action_just_pressed("jump") and ground: 
		jumping = true
		velocity.y = jump_speed if not crouched else jump_speed*0.9

	# initial crouch input check
	if Input.is_action_just_pressed("crouch"):
		if stumped:
			stumped = false
		else:
			crouched = true
			time_iterators.crouch = 1 - time_iterators.crouch

	# Crouch release input check
	# Also has a boolean, "stumped," for ensuring that the player eventually stands up 
	# if the player could not stand up when the button was initially released.
	if Input.is_action_just_released("crouch") or stumped:
		if headroom.get_collider() == null:
			crouched = false
			time_iterators.crouch = 1 - time_iterators.crouch
			stumped = false
		else:
			stumped = true
	
	# ensure that 
	var pickup = true
	
	if Input.is_action_just_pressed("throw"):
		hand.rotation = Vector3(0,0,0)
		if held_object != null:
			held_object.throw()
			held_object = null
			pickup = false
	
	if Input.is_action_just_pressed("drop"):
		hand.rotation = Vector3(0,0,0)
		if held_object != null:
			held_object.drop()
			held_object = null
			pickup = false
	
	if Input.is_action_just_pressed("pick_up"):
		if picker.is_colliding() and pickup:
			var object = picker.get_collider()
			if object.get_class() == "RigidBody":
				hand.global_rotation = object.global_rotation
				var distance = camera.global_translation.distance_to(object.global_translation)
				print(distance)
				arm.spring_length = min(distance, max_hold_length)
				object.start_being_held_by(hand)
				held_object = object
	
	if Input.is_action_just_pressed("interact"):
		if picker.is_colliding():
			var object = picker.get_collider()
			if object.has_method("interact"):
				object.interact(self)

func _ready():
	set_collision_layer_bit(3, false)
	set_collision_mask_bit(3, false)

func _process(delta):
	if paused:
		return
	hud.update_status(get_status_string())

func _physics_process(delta):
	
	if paused:
		return
	for x in time_iterators.keys():
		if time_iterators[x] < 1:
			time_iterators[x] += (delta * iterator_factors[x])
		if time_iterators[x] > 1:
			time_iterators[x] = 1.0
	
	if ground:
		if jumping:
			jumping = false

	if get_slide_count() > 1:
		var collisioner = get_slide_collision(get_slide_count() - 1)
		velocity +=  gravity * delta
	else:
		velocity +=  gravity * delta
	
	get_input(delta)
	update_flashlight()


	if Input.is_action_just_pressed("toggle_flashlight"):
		flashlight.visible = not flashlight.visible
	
	var snap = Vector3.DOWN if not (jumping or ground) else Vector3.ZERO
	if not jumping:
		velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(52), false)
	else:
		velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, deg2rad(52), false)

	
	ground = is_on_floor()


func _unhandled_input(event):
	if event.is_action_pressed("increase_hold_length"):
		if held_object != null:
			if arm.spring_length < max_hold_length:
				arm.spring_length += 0.1
	if event.is_action_pressed("decrease_hold_length"):
		if held_object != null:
			if arm.spring_length > min_hold_length:
				arm.spring_length -= 0.1
	if paused or child_scene:
		return
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("rotate_object"):
			if event.relative.x > 0:
				hand.rotate_y(-lerp(0, spin, event.relative.x/10))
			elif event.relative.x < 0:
				hand.rotate_y(-lerp(0, spin, event.relative.x/10))
			if event.relative.y > 0:
				hand.rotate_x(-lerp(0, spin, event.relative.y/10))
			elif event.relative.y < 0:
				hand.rotate_x(-lerp(0, spin, event.relative.y/10))
		else:
			time_iterators.flashlight_catchup = flashlight_starting_time
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if event.relative.x > 0:
				rotate_y(-lerp(0, spin, event.relative.x/10))
			elif event.relative.x < 0:
				rotate_y(-lerp(0, spin, event.relative.x/10))
			if event.relative.y > 0 && camera.rotation.x >= -PI/2:
				camera.rotate_x(-lerp(0, spin, event.relative.y/10))
			elif event.relative.y < 0 && camera.rotation.x <= PI/2:
				camera.rotate_x(-lerp(0, spin, event.relative.y/10))

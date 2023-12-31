# This script is inherited by all holdable physics objects. It is what allows them to be held.
class_name PhysicsEntityHoldable extends RigidBody

export var linear_restitution_force = 1000.0
export var angular_restitution_force = 16.0
export var held_linear_damp = 30.0
export var held_angular_damp = 10.0
export var throw_force = 15.0

export var child_scene = false

onready var original_position = global_translation

var target_spatial = null

var just_thrown = false
var just_dropped = false
var sleep = false
# goals: entities must be able to be picked up and dropped and thrown and move through portals
# most of these things I think should be handled in other places though, except maybe the portal one.


func reset_target():
	linear_damp = -1
	angular_damp = -1
	target_spatial = null
	just_thrown = false
	just_dropped = false
	set_collision_mask_bit(2, true)

func start_being_held_by(target: Spatial):
	reset_target()
	set_collision_mask_bit(2, false)
	linear_damp = held_linear_damp
	angular_damp = held_angular_damp
	target_spatial = target

func freeze():
	sleep = true

func unfreeze():
	sleep = false

func throw():
	just_thrown = true

func drop():
	just_dropped = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if child_scene:
		pause_mode = Node.PAUSE_MODE_PROCESS


func _physics_process(delta):
	if global_translation.y < -1000:
		reset_target()
		global_translation = original_position
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


# This function runs in addition to the default force integration algorithm. 
# It enforces relative positioning for the object and target_spatial, similar to
# a constraint in source engine.
func _integrate_forces(state):
	
	
	if just_dropped:
		reset_target()
	elif just_thrown:
		state.apply_central_impulse(throw_force * -target_spatial.global_transform.basis.z)
		reset_target()
	
	# if the 
	elif target_spatial != null:
		state.add_central_force( linear_restitution_force * (target_spatial.global_translation - global_translation))
		state.add_torque(angular_restitution_force * global_transform.basis.y.cross(target_spatial.global_transform.basis.y))
		state.add_torque(angular_restitution_force * global_transform.basis.z.cross(target_spatial.global_transform.basis.z))

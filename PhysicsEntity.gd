class_name PhysicsEntityHoldable extends RigidBody


export var linear_restitution_force = 1000
export var angular_restitution_force = 16
export var held_linear_damp = 30
export var held_angular_damp = 10
export var throw_force = 15
export var inverse_drop_force = 30

export var child_scene = false

onready var original_position = global_translation

var target_spatial = null

var just_thrown = false
var just_dropped = false
# goals: entities must be able to be picked up and dropped and thrown and move through portals
# most of these things I think should be handled in other places though, except maybe the portal one.


func reset_target():
	linear_damp = -1
	angular_damp = -1
	target_spatial = null
	just_thrown = false
	just_dropped = false



func start_being_held_by(target: Spatial):
	reset_target()
	linear_damp = held_linear_damp
	angular_damp = held_angular_damp
	target_spatial = target

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

func _integrate_forces(state):

	if just_dropped:
		reset_target()
	elif just_thrown:
		state.apply_central_impulse(throw_force * -target_spatial.global_transform.basis.z)
		reset_target()
	elif target_spatial != null:
		state.add_central_force( linear_restitution_force * (target_spatial.global_translation - global_translation))
		state.add_torque(angular_restitution_force * global_transform.basis.y.cross(target_spatial.global_transform.basis.y))
		state.add_torque(angular_restitution_force * global_transform.basis.z.cross(target_spatial.global_transform.basis.z))

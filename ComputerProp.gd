class_name Computer extends PhysicsEntityHoldable

export var grabbed_fov = 10

onready var screen_material = $computer_mesh.get_surface_material(2)

onready var stored_floppy = null
onready var view_grabbed = false
var camera_starting_transform = null
var camera_starting_fov = 0
var grabbed_player = null
var time_since_view_grabbed = 0.0
var time_since_ejected = 0.0

func on_body_entered(body: PhysicsBody):
	if stored_floppy == null and time_since_ejected > 2:

		if body.get_script() != null and body.get_script().get_path().begins_with("res://Floppy"):
			floppy_inserted(body)

func on_animation_started(anim_name):
	if stored_floppy != null:
		$Dummy/FloppyMesh.mesh = stored_floppy.get_floppy_mesh()

func on_animation_finished(anim_name):
	if(anim_name == "Eject"):
		floppy_ejected()
	if (anim_name == "Insert"):
		stored_floppy.insert()
		update_screen_path(stored_floppy.get_viewport_path())

func update_screen_path(path):
	screen_material.albedo_texture.viewport_path = path

func floppy_ejected():
	stored_floppy.global_transform = $Dummy/FloppyMesh.global_transform
	stored_floppy.visible = true
	stored_floppy.mode = RigidBody2D.MODE_RIGID
	stored_floppy = null
	if view_grabbed:
		release_screen()
	$AnimationPlayer.play("Empty")
	update_screen_path($Viewport.get_path())

func floppy_inserted(floppy):
	floppy.reset_target()
	stored_floppy = floppy
	stored_floppy.mode = RigidBody2D.MODE_STATIC
	stored_floppy.global_translation += Vector3(0,1000,0)
	stored_floppy.visible = false
	
	$AnimationPlayer.play("Insert")

func _process(delta):
	time_since_ejected += delta
	if view_grabbed:
		if time_since_view_grabbed < 1:
			time_since_view_grabbed += delta
		elif time_since_view_grabbed > 1:
			time_since_view_grabbed = 1
		else:
			stored_floppy.focus()
		grabbed_player.camera.global_transform = camera_starting_transform.interpolate_with($DummyCamera.global_transform, time_since_view_grabbed)
		grabbed_player.camera.fov = lerp(camera_starting_fov, grabbed_fov, time_since_view_grabbed)

#export (ViewportTexture) var viewport_texture
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area.connect("body_entered", self,"on_body_entered")
	$AnimationPlayer.connect("animation_finished", self,"on_animation_finished")
	$AnimationPlayer.connect("animation_started", self,"on_animation_started")
	
	#$computer_mesh.mesh.surface_get_material(0).albedo_texture = viewport_texture

func grab_screen(player):
	reset_target()
	#get_tree().paused = true
	view_grabbed = true
	player.paused = true
	time_since_view_grabbed = 0.0
	camera_starting_transform = player.camera.global_transform
	camera_starting_fov = player.camera.fov
	grabbed_player = player

func release_screen():
	grabbed_player.paused = false
	grabbed_player.camera.global_transform = camera_starting_transform
	grabbed_player.camera.fov = camera_starting_fov
	grabbed_player = null
	view_grabbed = false
	#get_tree().paused = false

func interact(player):
	if view_grabbed:
		release_screen()
	elif stored_floppy != null:
		if player.is_picking_area($Area):
			time_since_ejected = 0
			$AnimationPlayer.play("Eject")
		else:
			grab_screen(player)

			stored_floppy.connect("unfocus", self, "release_screen")





# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

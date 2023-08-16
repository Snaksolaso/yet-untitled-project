class_name Limen extends CSGMesh

signal player_contact(portal)

var playerbody = null

onready var local_camera = $Viewport/Camera
onready var local_flashlight = $Viewport/Camera/Flashlight
onready var viewport = $Viewport
onready var visibility_notifier = $VisibilityNotifier


# if enabled in the node, will not teleport player upon contact with area.
export var window = false

var area = null
var render = false

var not_duplicate = 0.0


var t = 0.0
func _ready():
#	if viewport == null:
#		if self.name.begins_with("LimenB"):
#			LIMEN_B.instance()
#
	
	if $Area != null:
		area = $Area
	#.set_shader_param("viewport_path", viewport.get_path())
	pass # Replace with function body.


# Sets the local camera's rotation and position to be equal to those of player's head, relative to the paired portal.
# This is what makes the portal effect work. 
# Needs: 
func move_local_camera(player, paired_portal):
	var paired_camera = paired_portal.get_node("Viewport/Camera")
	var playercam = player.get_node("CameraPivot/Camera")
	var distance = player.global_translation.distance_to(paired_portal.global_translation)
	
	if paired_portal.render:

		local_camera.fov = playercam.fov

		# the following part was originally a separate function. I should eventually rewrite this to have less redundant checks.
			#move stuff
		local_camera.transform = global_transform * paired_portal.transform.affine_inverse() * playercam.global_transform
		local_flashlight.global_translation.y = player.flashlight.global_translation.y - paired_portal.global_translation.y + global_translation.y
			
		local_flashlight.visible = player.flashlight.visible
		
		local_flashlight.rotation.x = player.flashlight.rotation.x - player.camera.rotation.x
		local_flashlight.rotation.x = player.flashlight.rotation.x - player.camera.rotation.x
		local_flashlight.rotation.y = player.flashlight.rotation.y - player.rotation.y #player.lerp_angle(flashlight.rotation.y, rotation.y, time_iterators.flashlight_catchup)
		local_flashlight.spot_angle = player.flashlight.spot_angle
		local_flashlight.spot_range = player.flashlight.spot_range
		
		
		var proximity = paired_portal.global_translation.distance_to(player.global_translation)
			
		if proximity > 40:
			proximity = 40
			
		viewport.size.y = OS.get_window_safe_area().size.y * (1-proximity/40)
		viewport.size.x = OS.get_window_safe_area().size.x * (1-proximity/40)
		
	else: 
		viewport.size = Vector2(0,0)
		paired_portal.local_flashlight.visible = false

func update_portal_mesh_texture(paired_portal: Spatial):
	var portal_mat = $MeshInstance.get_surface_material(0)
	var newport = portal_mat.get_shader_param("viewport_texture")
	newport.viewport_path = "../" + paired_portal.name + "/Viewport"
	portal_mat.set_shader_param("viewport_texture", newport)
	if window:
		for i in $MeshInstance.get_surface_material_count():
			if i == 0:
				pass
			else:
				var mat = $MeshInstance.get_surface_material(i).duplicate()
				mat.transparent = true
				mat.albedo.alpha = 0
				$MeshInstance.set_surface_material(i, mat)

func teleport_player(player, paired_portal: Spatial):
	
	var paired_camera = paired_portal.local_camera
	var paired_flashlight = paired_portal.local_flashlight
	not_duplicate = 0.0
	player.time_iterators.flashlight_focus = 1.0
	
	player.global_translation = paired_camera.global_translation - Vector3(0,0.551,0)
	var angle_diff = fmod(paired_camera.global_rotation.y - player.global_rotation.y, 2*PI)
	player.global_rotation.y = paired_camera.global_rotation.y
	player.velocity = player.velocity.rotated(Vector3.UP, angle_diff)
	
	# Prevent any visible anomalies that might be caused by the sudden teleportation.
	paired_portal.render = true
	if paired_portal.local_flashlight != null:
		player.flashlight.global_rotation = paired_portal.local_flashlight.global_rotation
		paired_portal.local_flashlight.visible = false
		local_flashlight.visible = false
	var prev = player.time_iterators.flashlight_focus
	player.update_flashlight()
	player.time_iterators.flashlight_focus = prev
	move_local_camera(player, paired_portal)

func _physics_process(delta):
	if not render:
		viewport.size = Vector2(2,2)
	if not window and area != null and playerbody != null and area.overlaps_body(playerbody) and not_duplicate > 0.1:
		emit_signal("player_contact", self)
	else:
		not_duplicate += delta

extends PhysicsEntityHoldable

func _ready():
	if child_scene:
		pause_mode = Node.PAUSE_MODE_PROCESS

func interact(player):
	$Flashlight.visible = not $Flashlight.visible
	$entity_90_mesh_instance.get_surface_material(3).emission_enabled = $Flashlight.visible

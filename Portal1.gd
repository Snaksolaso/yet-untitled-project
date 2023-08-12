extends CSGMesh
#PORTAL 1 SCRIPT

onready var cam = get_node("Viewport/Camera")
onready var playerbody = get_node("../Spatial/KinematicBody")
onready var playercam = get_node("../Spatial/KinematicBody/Camera")

onready var portal2 =  get_node("../Portal2")
var t = 0.0
var links = {}

func _ready():
	
	pass 

func move_camera(portal: Node) -> void: 
	var linked: Node = portal2 
	var up := Vector3(0, 1, 0) 
	var trans: Transform = linked.global_transform.affine_inverse() * (playercam.global_transform)
	
	
	cam.transform = trans
	#var cam_pos: Transform = cam.global_transform 
	#cam.global_transform = trans

func _process(delta):
	t += delta
	if t > 3:
		#move_camera(cam)
		pass
		

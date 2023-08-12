extends CSGMesh
#PORTAL 1 SCRIPT

onready var cam = get_node("Viewport/Camera")
onready var playerbody = get_node("../Spatial/KinematicBody")
onready var playercam = get_node("../Spatial/KinematicBody/Camera")

onready var linked =  get_node("../Portal1")
var t = 0.0
var links = {}

func _ready():
	
	pass 

func move_camera(portal: Node) -> void: 
	var trans: Transform = linked.global_transform.inverse() * (playercam.global_transform)
	var up := Vector3(0, 1, 0) 
	trans = trans.rotated(up, PI)
	
	
	cam.transform = trans
	#var cam_pos: Transform = cam.global_transform 
	#cam.global_transform = trans

func _process(delta):
	t += delta
	if t > 3:
		#move_camera(cam)
		pass
		

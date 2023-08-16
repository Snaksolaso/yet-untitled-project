extends Spatial

# saved for calculations determining the current paired portal of a portal with multiple pairs.
# my thinking is that portals will always link to the last paired portal, if it is one of their pairs,
# until the player has seen it and looked away, at which point it will revert to the first paired portal.

export var links = { 
"PortalA":["PortalB"], 
"PortalB":["PortalA"], 
"PortalA2":["PortalB2"], 
"PortalB2":["PortalA2"], 
"WindowA1":["WindowB1"], 
"WindowB1":["WindowA1"], 
"WindowA2":["WindowB2"], 
"WindowB2":["WindowA2"], 
#"LimineOriginis":["LimenB1"], 
#"LimenB1":["LimineOriginis"], 
"LimenA2":["LimenB2"], 
"LimenB2":["LimenA2"], 
#"LimenA3":["LimenB2"],
"LimenA4":["LimenB4"],
"LimenB4":["LimenA4"],
"LimenA5":["LimenB5"],
"LimenB5":["LimenA5"],
}

var portals = {}
var last_portal = null

onready var playerscene = get_node("../Player")
onready var player = playerscene.get_node("KinematicBody")

# inserts (or moves, if portal is already a pair of) given portal's name to front of pair list
# also updates relevant parameters to ensure their synchronicity. 
func set_current_pair(portal: Spatial, pair_name: String):
	var pairs = links.get(portal.name)
	if remove_pair(portal, pair_name):
		remove_pair(get_node(pair_name), portal.name)
	pairs.push_front(pair_name)
	links[portal.name] = pairs
	portal.update_paired_portal()
	return true

func remove_pair(portal: Spatial, pair_name: String):
	var pairs = links.get(portal.name) as Array
	if pairs.has(pair_name):
		pairs.remove(pairs.find(pair_name))
		return true
	return false

func insert_pair(portal: Spatial, pair_name: String, index: int):
	pass

# get portal's current pair
func get_current_pair(portal: Spatial):
	if portal != null:
		var pairs = links.get(portal.name)
		var closest_pair = get_node(pairs.front())
		if (last_portal != null \
		and (links.get(last_portal.name).has(portal) \
		and player != null \
		and closest_pair.global_translation.distance_to(player.global_translation) > 10)):
			return last_portal
		return closest_pair
	else:
		return null

func update_last_portal(portal: Spatial):
	last_portal = portal
	
func link_portals(portalA: Spatial, portalB: Spatial):
	pass

func update_material(portal: Spatial):
	var pairs = links.get(portal.name)
	pass

func _on_player_contact(portal: Node):
	var pair = get_current_pair(portal)
	portal.teleport_player(player, pair)


func _on_entered_visibility(node: Spatial):
	var parent = node.get_parent()
	if links.keys().has(parent.name):
		var portal = get_node(parent.name)
		portal.render = true

func _on_left_visibility(node: Spatial):
	var parent = node.get_parent()
	if links.keys().has(parent.name):
		var portal = get_node(parent.name)
		portal.render = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for key in portals.keys():
		var portal = get_node(key)
		var pair = get_current_pair(get_node(key))
		if player.global_translation.distance_to(pair.global_translation) < 80:
			portal.move_local_camera(player, pair)

func _physics_process(delta):
	
	pass


func _ready():
	player.visibility_area.connect("area_entered", self, "_on_entered_visibility")
	player.visibility_area.connect("area_exited", self, "_on_left_visibility")
	for key in links.keys():
		var portal = self.get_node(key)
		if portal != null:
			portals[key] = portal
			var pair = get_current_pair(portal)
			portal.playerbody = player
			portal.connect("player_contact", self, "_on_player_contact")
			portal.update_portal_mesh_texture(pair)
			

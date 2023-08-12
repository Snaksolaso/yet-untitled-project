extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var status_label = get_node("Status/StatusLabel")


func update_status(status):
	status_label.text = status

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

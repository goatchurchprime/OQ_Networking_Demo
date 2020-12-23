extends Spatial

var info_text = """Hello there
"""

# Called when the node enters the scene tree for the first time.
func _ready():
	vr.initialize()
	$OQ_UILabel.set_label_text(info_text);
	pass

func glidergo():
	pass # Replace with function body.

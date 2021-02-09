extends Spatial

func _ready():
	pass # Replace with function body.

remote func spawnotherplayer(playerinfo):
	assert (get_tree().get_rpc_sender_id() == playerinfo["networkID"])
	var pname = str(playerinfo["networkID"])
	if not has_node(pname):
		var playerpuppet = preload("res://PlayerPuppet.tscn").instance()
		playerpuppet.set_name(pname)
		add_child(playerpuppet)
		print("Adding playerpuppet: ", playerinfo["networkID"])
	else:
		print("** playerpuppet already exists: ", playerinfo["networkID"])
		
func removeotherplayer(id):
	var pname = str(id)
	if has_node(pname):
		var playerpuppet = get_node(pname)
		remove_child(playerpuppet)
		playerpuppet.queue_free()
		print("Removing playerpuppet: ", id)
	else:
		print("** playerpuppet already removed: ", id)


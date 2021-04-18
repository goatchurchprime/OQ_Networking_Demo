extends Spatial

var playerframestacks = { }

onready var LocalPlayer = $LocalPlayer

func newremoteplayer(avatardata):
	var remoteplayer = get_node_or_null(avatardata["playernodename"])
	if remoteplayer == null:
		remoteplayer = load(avatardata["avatarsceneresource"]).instance()
		remoteplayer.initavatar(avatardata)
		add_child(remoteplayer)
		print("Adding remoteplayer: ", avatardata["playernodename"])
	else:
		print("** remoteplayer already exists: ", avatardata["playernodename"])
	return remoteplayer
	
func removeremoteplayer(playernodename):
	var remoteplayer = get_node_or_null(playernodename)
	if remoteplayer != null:
		remove_child(remoteplayer)
		remoteplayer.queue_free()
		playerframestacks.erase(playernodename)
		print("Removing remoteplayer: ", playernodename)
	else:
		print("** remoteplayer already removed: ", playernodename)
	

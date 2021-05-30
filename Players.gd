extends Spatial

func newremoteplayer(avatardata):
	var remoteplayer = get_node_or_null(avatardata["playernodename"])
	if remoteplayer == null:
		remoteplayer = load(avatardata["avatarsceneresource"]).instance()
		assert (not remoteplayer.islocalplayer)
		remoteplayer.initavatar(avatardata)
		var remoteplayerframe = preload("res://RemotePlayerFrame.tscn").instance()
		remoteplayer.add_child(remoteplayerframe)
		add_child(remoteplayer)
		if "framedata0" in avatardata:
			remoteplayer.get_node("PlayerFrame").networkedavatarthinnedframedata(avatardata["framedata0"])
		print("Adding remoteplayer: ", avatardata["playernodename"], "  ", remoteplayer.islocalplayer)
	else:
		print("** remoteplayer already exists: ", avatardata["playernodename"])
	return remoteplayer
	
func removeremoteplayer(playernodename):
	var remoteplayer = get_node_or_null(playernodename)
	if remoteplayer != null:
		remove_child(remoteplayer)
		remoteplayer.queue_free()
		print("Removing remoteplayer: ", playernodename)
	else:
		print("** remoteplayer already removed: ", playernodename)
	

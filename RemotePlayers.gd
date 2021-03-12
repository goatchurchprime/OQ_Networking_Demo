extends Spatial

var playerframestacks = { }

func newremoteplayer(t1, nname, pdat, tlocal):
	var remoteplayer = get_node_or_null(nname)
	if remoteplayer == null:
		remoteplayer = preload("res://RemotePlayer.tscn").instance()
		remoteplayer.set_name(nname)
		remoteplayer.get_node("HeadCam/csgheadmesh/skullcomponent").material.albedo_color = pdat["playercolour"]
		add_child(remoteplayer)
		playerframestacks[nname] = FI.FrameStack.new(pdat["frameattributes"])
		print("Adding remoteplayer: ", nname)
	else:
		print("** remoteplayer already exists: ", pdat["nname"])
	playerframestacks[nname].setinitialframe(t1, pdat, tlocal)
	if nname == "Doppelganger":
		var attributevalues = playerframestacks[nname].valuestack[0]
		remoteplayer.transform = Transform(attributevalues[FI.CFI.XRBASIS], attributevalues[FI.CFI.XRORIGIN])
	return remoteplayer
	
func removeremoteplayer(nname):
	var remoteplayer = get_node_or_null(nname)
	if remoteplayer != null:
		remove_child(remoteplayer)
		remoteplayer.queue_free()
		playerframestacks.erase(nname)
		print("Removing remoteplayer: ", nname)
	else:
		print("** remoteplayer already removed: ", nname)
	
func nextcompressedframe(t1, nname, cf, tlocal):
	playerframestacks[nname].expandappendframe(t1, cf, tlocal)
	
func _process(delta):
	var tlocal = OS.get_ticks_msec()*0.001
	for nname in playerframestacks:
		var remoteplayer = get_node(nname)
		var t = tlocal - playerframestacks[nname].mintimeshift - playerframestacks[nname].furtherbacktime
		var attributevalues = playerframestacks[nname].interpolatevalues(t)
		if nname != "Doppelganger":
			remoteplayer.transform = Transform(attributevalues[FI.CFI.XRBASIS], attributevalues[FI.CFI.XRORIGIN])
		remoteplayer.get_node("HeadCam").transform = Transform(attributevalues[FI.CFI.XRCAMERABASIS], attributevalues[FI.CFI.XRCAMERAORIGIN])
		remoteplayer.get_node("HandLeft").transform = Transform(attributevalues[FI.CFI.XRLEFTBASIS], attributevalues[FI.CFI.XRLEFTORIGIN])
		remoteplayer.get_node("HandRight").transform = Transform(attributevalues[FI.CFI.XRRIGHTBASIS], attributevalues[FI.CFI.XRRIGHTORIGIN])


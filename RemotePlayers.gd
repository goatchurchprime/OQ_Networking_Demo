extends Spatial

var playerframestacks = { }

func newremoteplayer(t1, id, pdat):
	var nname = "R%d" % id
	if not has_node(nname):
		var remoteplayer = preload("res://RemotePlayer.tscn").instance()
		remoteplayer.set_name(nname)
		remoteplayer.get_node("HeadCam/csgheadmesh/skullcomponent").material.albedo_color = pdat["playercolour"]
		if pdat["platform"] == "Pancake":
			remoteplayer.get_node("HeadCam/csgheadmesh").mesh.size.x = 0.15
		add_child(remoteplayer)
		playerframestacks[nname] = FrameInterpolation.FrameStack.new(pdat["frameattributes"])
		print("Adding remoteplayer: ", nname)
		remoteplayer.set_network_master(id)
	else:
		print("** remoteplayer already exists: ", pdat["nname"])
		
func removeremoteplayer(id):
	var nname = "R%d" % id
	if has_node(nname):
		var remoteplayer = get_node(nname)
		remove_child(remoteplayer)
		remoteplayer.queue_free()
		playerframestacks.erase(nname)
		print("Removing remoteplayer: ", nname)
	else:
		print("** remoteplayer already removed: ", nname)
	
func nextcompressedframe(t1, id, cf):
	var nname = "R%d" % id
	playerframestacks[nname].expandappendframe(t1, cf)
	
func _process(delta):
	var t = OS.get_ticks_msec()*0.001 - 0.1
	for nname in playerframestacks:
		var remoteplayer = get_node(nname)
		var attributevalues = playerframestacks[nname].interpolatevalues(t)
		remoteplayer.transform = Transform(attributevalues[1], attributevalues[0])
		remoteplayer.get_node("HeadCam").transform = Transform(attributevalues[3], attributevalues[2])
		remoteplayer.get_node("HandLeft").transform = Transform(attributevalues[5], attributevalues[4])
		remoteplayer.get_node("HandRight").transform = Transform(attributevalues[7], attributevalues[6])

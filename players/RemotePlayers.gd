extends Spatial

var playerframestacks = { }

func newremoteplayer(nname, pdat, tlocal):
	var remoteplayer = get_node_or_null(nname)
	if remoteplayer == null:
		remoteplayer = preload("res://players/RemotePlayer.tscn").instance()
		remoteplayer.set_name(nname)
		remoteplayer.get_node("HeadCam/csgheadmesh/skullcomponent").material.albedo_color = pdat["playercolour"]
		add_child(remoteplayer)
		playerframestacks[nname] = FI.FrameStack.new(pdat["frameattributes"])
		print("Adding remoteplayer: ", nname)
	else:
		print("** remoteplayer already exists: ", pdat["nname"])
	playerframestacks[nname].setinitialframe(pdat, tlocal)
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
	
func nextcompressedframe(nname, cf, tlocal):
	playerframestacks[nname].expandappendframe(cf, tlocal)
	
const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];
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

		var handleftvisible = (attributevalues[FI.CFI.XRLEFTHANDCONF] > 0.0)
		remoteplayer.get_node("HandLeft/OculusQuestTouchController_Left").visible = not handleftvisible
		remoteplayer.get_node("HandLeft/OculusQuestHand_Left").visible = handleftvisible
		if handleftvisible:
			var skeleton = remoteplayer.get_node("HandLeft/OculusQuestHand_Left/ArmatureLeft/Skeleton")
			var D_vrapi_bone_orientations = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left")._vrapi_bone_orientations
			var orgskel = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left/OculusQuestHand_Left/ArmatureLeft/Skeleton")
			remoteplayer.get_node("HandLeft/OculusQuestHand_Left").scale = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left/OculusQuestHand_Left").scale
			#for i in range(19):
				#skeleton.set_bone_pose(_vrapi2hand_bone_map[i], Transform(attributevalues[FI.CFI.XRLEFTHANDROOT+i]))
				#skeleton.set_bone_pose(_vrapi2hand_bone_map[i], Transform(D_vrapi_bone_orientations[i]));
			for i in range(24):
				skeleton.set_bone_pose(i, orgskel.get_bone_pose(i))
				

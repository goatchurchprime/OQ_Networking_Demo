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
	
func nextcompressedframe(nname, cf, tlocal):
	playerframestacks[nname].expandappendframe(cf, tlocal)
	
const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];
func _process(delta):
	var tlocal = OS.get_ticks_msec()*0.001
	return
	
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
			remoteplayer.get_node("HandLeft/OculusQuestHand_Left").scale = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left/OculusQuestHand_Left").scale
			#var D_vrapi_bone_orientations = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left")._vrapi_bone_orientations
			#var orgskel = get_node("/root/Main/OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left/OculusQuestHand_Left/ArmatureLeft/Skeleton")
			for i in range(19):
				skeleton.set_bone_pose(_vrapi2hand_bone_map[i], Transform(attributevalues[FI.CFI.XRLEFTHANDROOT+i]))
				#skeleton.set_bone_pose(_vrapi2hand_bone_map[i], Transform(D_vrapi_bone_orientations[i]));
			#for i in range(24):
			#	skeleton.set_bone_pose(i, orgskel.get_bone_pose(i))
				

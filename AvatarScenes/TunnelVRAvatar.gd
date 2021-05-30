extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")
var doppelgangernode = null

onready var handlefthand = $HandLeft/OculusQuestHand_Left
onready var handleftcontroller = $HandLeft/OculusQuestTouchController_Left_Reactive
onready var handleftskeleton = handlefthand.find_node("Skeleton")
onready var handleftmesh = handleftskeleton.find_node("?_handMeshNode")
onready var handleftbonerestposeinverses = [ ]
onready var handleftboneposes = [ ]

onready var handrighthand = $HandRight/OculusQuestHand_Right
onready var handrightcontroller = $HandRight/OculusQuestTouchController_Right_Reactive
onready var handrightskeleton = handrighthand.find_node("Skeleton")
onready var handrightmesh = handrightskeleton.find_node("?_handMeshNode")
onready var handrightbonerestposeinverses = [ ]
onready var handrightboneposes = [ ]

const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];
const handskeletonbonecount = 24

var platform = "notset"
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])
var osuniqueid = OS.get_unique_id()
var networkID = 0   # 0:unconnected, 1:server, -1:connecting, >1:connected to client

enum CFI {
	ID 				= -2,
	TIMESTAMP 		= -1, 
	PREV_TIMESTAMP	= -3, 
	LOCAL_TIMESTAMP	= -4, 
		
	BITCONTROLLERLEFTVIZ 	= 0b00010000,
	BITCONTROLLERRIGHTVIZ 	= 0b00100000,
	BITHANDLEFTVIZ 			= 0b01000000, 
	BITHANDRIGHTVIZ 		= 0b10000000, 

	ORIGINTRANS_POS		= 100,
	ORIGINTRANS_QUAT 	= 110,
	HEADCAMTRANS_POS	= 120,
	HEADCAMTRANS_QUAT	= 130,
	HANDLEFTTRANS_POS	= 140,
	HANDLEFTTRANS_QUAT	= 150,
	HANDRIGHTTRANS_POS	= 160,
	HANDRIGHTTRANS_QUAT	= 170,
	VIZBITS				= 180,
	HANDLEFTHANDQUATS	= 210,
	HANDRIGHTHANDQUATS	= 310,
}

func _ready():
	handleftbonerestposeinverses.resize(handskeletonbonecount)
	handleftboneposes.resize(handskeletonbonecount)
	handrightbonerestposeinverses.resize(handskeletonbonecount)
	handrightboneposes.resize(handskeletonbonecount)
	handleftskeleton.set_bone_rest(0, Transform())
	handrightskeleton.set_bone_rest(0, Transform())
	for i in range(handskeletonbonecount):
		handleftbonerestposeinverses[i] = Quat(handleftskeleton.get_bone_rest(i).basis.inverse())
		handleftboneposes[i] = Quat()
		handrightbonerestposeinverses[i] = Quat(handrightskeleton.get_bone_rest(i).basis.inverse())
		handrightboneposes[i] = Quat()

var localavatardisplacement = Vector3(0,0,-0.1)*0
func processlocalavatarposition(delta):
	if vr.vrOrigin == null:
		return
	transform = vr.vrOrigin.transform 
	transform.origin = vr.vrOrigin.transform.origin + localavatardisplacement
	$HeadCam.transform = vr.vrCamera.transform 

	$HandLeft.transform = vr.leftController.transform 
	if vr.leftController.is_hand:
		if vr.leftController._hand_model.tracking_confidence >= 1.0:
			handlefthand.visible = true
			handlefthand.scale = vr.leftController._hand_model.scale
			for i in range(len(_vrapi2hand_bone_map)):
				var im = _vrapi2hand_bone_map[i]
				handleftboneposes[im] = handleftbonerestposeinverses[im]*vr.leftController._hand_model._vrapi_bone_orientations[i]
				handleftskeleton.set_bone_pose(im, handleftboneposes[im])
		else:
			handlefthand.visible = false
		handleftcontroller.visible = false
	else:
		handlefthand.visible = false
		handleftcontroller.visible = true

	$HandRight.transform = vr.rightController.transform 
	if vr.rightController.is_hand:
		if vr.rightController._hand_model.tracking_confidence >= 1.0:
			handrighthand.visible = true
			handrighthand.scale = vr.rightController._hand_model.scale
			for i in range(len(_vrapi2hand_bone_map)):
				var im = _vrapi2hand_bone_map[i]
				handrightboneposes[im] = handrightbonerestposeinverses[im]*vr.rightController._hand_model._vrapi_bone_orientations[i]
				handrightskeleton.set_bone_pose(im, handrightboneposes[im])
		else:
			handrighthand.visible = false
		handrightcontroller.visible = false
	else:
		handrighthand.visible = false
		handrightcontroller.visible = true

		
func avatartoframedata():
	var vizbits = (CFI.BITCONTROLLERLEFTVIZ if handleftcontroller.visible else 0) | \
				  (CFI.BITCONTROLLERRIGHTVIZ if handrightcontroller.visible else 0) | \
				  (CFI.BITHANDLEFTVIZ if handlefthand.visible else 0) | \
				  (CFI.BITHANDRIGHTVIZ if handrighthand.visible else 0)
	var fd = { 
		CFI.ORIGINTRANS_POS:	transform.origin,
		CFI.ORIGINTRANS_QUAT:	transform.basis.get_rotation_quat(),
		CFI.HEADCAMTRANS_POS:	$HeadCam.transform.origin,
		CFI.HEADCAMTRANS_QUAT:	$HeadCam.transform.basis.get_rotation_quat(),
		CFI.HANDLEFTTRANS_POS:	$HandLeft.transform.origin, 
		CFI.HANDLEFTTRANS_QUAT:	$HandLeft.transform.basis.get_rotation_quat(), 
		CFI.HANDRIGHTTRANS_POS: $HandRight.transform.origin,
		CFI.HANDRIGHTTRANS_QUAT:$HandRight.transform.basis.get_rotation_quat(),
		CFI.VIZBITS:			vizbits 
	}
	if handlefthand.visible:
		for i in range(24):
			fd[CFI.HANDLEFTHANDQUATS+i] = handleftboneposes[i]
	if handrighthand.visible:
		for i in range(24):
			fd[CFI.HANDRIGHTHANDQUATS+i] = handrightboneposes[i]
	return fd

func framedatatoavatar(fd):
	transform = Transform(fd[CFI.ORIGINTRANS_QUAT], fd[CFI.ORIGINTRANS_POS])
	$HeadCam.transform = Transform(fd[CFI.HEADCAMTRANS_QUAT], fd[CFI.HEADCAMTRANS_POS])
	$HandLeft.transform = Transform(fd[CFI.HANDLEFTTRANS_QUAT], fd[CFI.HANDLEFTTRANS_POS])
	$HandRight.transform = Transform(fd[CFI.HANDRIGHTTRANS_QUAT], fd[CFI.HANDRIGHTTRANS_POS])

	var vizbits = fd[CFI.VIZBITS]
	handleftcontroller.visible = bool(vizbits & CFI.BITCONTROLLERLEFTVIZ)
	handrightcontroller.visible = bool(vizbits & CFI.BITCONTROLLERRIGHTVIZ)
	handlefthand.visible = bool(vizbits & CFI.BITHANDLEFTVIZ)
	handrighthand.visible = bool(vizbits & CFI.BITHANDRIGHTVIZ)
	if handlefthand.visible:
		for i in range(24):
			handleftboneposes[i] = fd[CFI.HANDLEFTHANDQUATS+i]
			handleftskeleton.set_bone_pose(i, handleftboneposes[i])
	if handrighthand.visible:
		for i in range(24):
			handrightboneposes[i] = fd[CFI.HANDRIGHTHANDQUATS+i]
			handrightskeleton.set_bone_pose(i, handrightboneposes[i])

func initavatar(avatardata):
	set_name(avatardata["playernodename"])
	platform = avatardata["platform"]
	$HeadCam/csgheadmesh/skullcomponent.material.albedo_color = avatardata["playercolour"]
	guardianpoly = avatardata["guardianpoly"]
	osuniqueid = avatardata["osuniqueid"]
	networkID = avatardata["networkid"]

func avatarinitdata():
	var avatardata = { "playernodename":get_name(),
					   "platform":platform, 
					   "playercolour":$HeadCam/csgheadmesh/skullcomponent.material.albedo_color, 
					   "guardianpoly":guardianpoly, 
					   "avatarsceneresource":filename, 
					   "osuniqueid":osuniqueid, 
					   "networkid":networkID
					 }
	return avatardata

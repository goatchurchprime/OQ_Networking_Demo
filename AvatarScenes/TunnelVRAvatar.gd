extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

onready var handlefthand = $HandLeft/OculusQuestHand_Left
onready var handleftcontroller = $HandLeft/OculusQuestTouchController_Left
onready var handleftskeleton = handlefthand.find_node("Skeleton")
onready var handleftmesh = handleftskeleton.find_node("?_handMeshNode")
onready var handleftbonerestposeinverses = [ ]
onready var handleftboneposes = [ ]

onready var handrighthand = $HandRight/OculusQuestHand_Right
onready var handrightcontroller = $HandRight/OculusQuestTouchController_Right
onready var handrightskeleton = handrighthand.find_node("Skeleton")
onready var handrightmesh = handrightskeleton.find_node("?_handMeshNode")
onready var handrightbonerestposeinverses = [ ]
onready var handrightboneposes = [ ]

const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];
const handskeletonbonecount = 24

var platform = "notset"
var playercolour = Color(1.0, 1.0, 1.0)
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

	ORIGINTRANS 		= 100,
	HEADCAMTRANS 		= 110,
	HANDLEFTTRANS		= 120,
	HANDRIGHTTRANS		= 130,
	VIZBITS				= 140,
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

var localavatardisplacement = Vector3(0,0,-0.1)
func arvrcontrolstoavatar():
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

func _process(delta):
	if islocalplayer and vr.vrOrigin != null:
		arvrcontrolstoavatar()
		
func avatartoframedata():
	var vizbits = (CFI.BITCONTROLLERLEFTVIZ if handleftcontroller.visible else 0) | \
				  (CFI.BITCONTROLLERRIGHTVIZ if handrightcontroller.visible else 0) | \
				  (CFI.BITHANDLEFTVIZ if handlefthand.visible else 0) | \
				  (CFI.BITHANDRIGHTVIZ if handrighthand.visible else 0)
	var fd = { 
		CFI.ORIGINTRANS:		transform,
		CFI.HEADCAMTRANS:		$HeadCam.transform,
		CFI.HANDLEFTTRANS:		$HandLeft.transform, 
		CFI.HANDRIGHTTRANS:		$HandRight.transform,
		CFI.VIZBITS:			vizbits 
	}
	if handlefthand.visible:
		for i in range(24):
			fd[CFI.HANDLEFTHANDQUATS+i] = handleftboneposes[i]
	if handrighthand.visible:
		for i in range(24):
			fd[CFI.FHANDRIGHTHANDQUATS+i] = handrightboneposes[i]
	return fd

func framedatatoavatar(fd):
	transform = fd[CFI.ORIGINTRANS]
	$HeadCam.transform = fd[CFI.HEADCAMTRANS]
	$HandLeft.transform = fd[CFI.HANDLEFTTRANS]
	$HandRight.set_transform(fd[CFI.HANDRIGHTTRANS])

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
	playercolour = avatardata["playercolour"]
	$HeadCam/csgheadmesh/skullcomponent.material.albedo_color = playercolour
	guardianpoly = avatardata["guardianpoly"]
	osuniqueid = avatardata["osuniqueid"]
	networkID = avatardata["networkid"]

func avatarinitdata():
	var avatardata = { "playernodename":get_name(),
					   "platform":platform, 
					   "playercolour":playercolour, 
					   "guardianpoly":guardianpoly, 
					   "avatarsceneresource":filename, 
					   "osuniqueid":osuniqueid, 
					   "networkid":networkID
					 }
	return avatardata

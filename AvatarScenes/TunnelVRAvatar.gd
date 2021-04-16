extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

onready var handlefthand = $HandLeft/OculusQuestHand_Left
onready var handleftskeleton = handlefthand.find_node("Skeleton")
onready var handleftmesh = handleftskeleton.find_node("?_handMeshNode")
onready var handleftbonerestposeinverses = [ ]
onready var handleftboneposes = [ ]

onready var handrighthand = $HandRight/OculusQuestHand_Right
onready var handrightskeleton = handrighthand.find_node("Skeleton")
onready var handrightmesh = handrightskeleton.find_node("?_handMeshNode")
onready var handrightbonerestposeinverses = [ ]
onready var handrightboneposes = [ ]

const _vrapi2hand_bone_map = [0, 23,  1, 2, 3, 4,  6, 7, 8,  10, 11, 12,  14, 15, 16, 18, 19, 20, 21];
const handskeletonbonecount = 24

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

func _process(delta):
	if islocalplayer and vr.vrOrigin != null:
		transform = vr.vrOrigin.transform 
		transform.origin = vr.vrOrigin.transform.origin + Vector3(0,0,-1)
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
			$HandLeft/OculusQuestTouchController_Left.visible = false
		else:
			handlefthand.visible = false
			$HandLeft/OculusQuestTouchController_Left.visible = true

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
			$HandRight/OculusQuestTouchController_Right.visible = false
		else:
			handrighthand.visible = false
			$HandRight/OculusQuestTouchController_Right.visible = true


func playerframedata(keepall):
	var fd = { 
		FI.CFI.XRORIGIN:		$OQ_ARVROrigin.transform.origin,
		FI.CFI.XRBASIS:			$OQ_ARVROrigin.transform.basis, 
		FI.CFI.XRCAMERAORIGIN:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.origin, 
		FI.CFI.XRCAMERABASIS:	$OQ_ARVROrigin/OQ_ARVRCamera.transform.basis,
		FI.CFI.XRLEFTORIGIN:	$OQ_ARVROrigin/OQ_LeftController.transform.origin, 
		FI.CFI.XRLEFTBASIS:		$OQ_ARVROrigin/OQ_LeftController.transform.basis, 
		FI.CFI.XRRIGHTORIGIN:	$OQ_ARVROrigin/OQ_RightController.transform.origin, 
		FI.CFI.XRRIGHTBASIS:	$OQ_ARVROrigin/OQ_RightController.transform.basis 
	}
	if keepall or ($OQ_ARVROrigin/OQ_LeftController.visible and $OQ_ARVROrigin/OQ_LeftController.has_node("Feature_HandModel_Left") and \
			$OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.model.visible):
		fd[FI.CFI.XRLEFTHANDCONF] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left.tracking_confidence
		for i in range(24):
			fd[FI.CFI.XRLEFTHANDROOT+i] = $OQ_ARVROrigin/OQ_LeftController/Feature_HandModel_Left._vrapi_bone_orientations[i]
		#print("finger ", fd[FI.CFI.XRLEFTHANDROOT+10])
	else:
		fd[FI.CFI.XRLEFTHANDCONF] = 0.0
	return fd


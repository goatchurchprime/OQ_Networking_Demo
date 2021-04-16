extends Spatial

onready var islocalplayer = (get_name() == "LocalPlayer")

func _process(delta):
	if islocalplayer and vr.vrOrigin != null:
		transform = vr.vrOrigin.transform 
		$HeadCam.transform = vr.vrCamera.transform 
		$HandLeft.transform = vr.leftController.transform 
		$HandRight.transform = vr.rightController.transform 
		if vr.leftController.is_hand:
			var lefthandmodel
			$HandLeft/OculusQuestHand_Left.visible = vr.leftController._hand_model.visible
			$HandLeft/OculusQuestTouchController_Left.visible = false
		else:
			$HandLeft/OculusQuestHand_Left.visible = false
			$HandLeft/OculusQuestTouchController_Left.visible = true

		if vr.rightController.is_hand:
			$HandRight/OculusQuestHand_Right.visible = vr.rightController._hand_model.visible
			$HandRight/OculusQuestTouchController_Right.visible = false
		else:
			$HandRight/OculusQuestHand_Right.visible = false
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


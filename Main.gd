extends Spatial

export var vrenabled = true

onready var NetworkGateway = $OQ_VisibilityToggle/OQ_UI2DCanvas.ui_control
onready var LocalPlayer = $Players/LocalPlayer

func _ready():
	randomize()
	$OQ_ARVROrigin.transform.origin.x += rand_range(-3, 3)
	$OQ_ARVROrigin.transform.origin.z += rand_range(-1, 1)
	var playercolour = Color.from_hsv(rand_range(0, 1), rand_range(0.5, 0.86), 0.75)
	print(ARVRServer.get_interfaces())
	if OS.has_feature("Server"):
		vrenabled = false
		LocalPlayer.platform = "Server"
		playercolour = Color(0.01, 0.01, 0.05)
	elif ARVRServer.find_interface("OVRMobile"):
		LocalPlayer.platform = "OVRMobile"
		vrenabled = true
	elif vrenabled and ARVRServer.find_interface("Oculus"):
		LocalPlayer.platform = "Oculus"
	elif vrenabled and ARVRServer.find_interface("OpenVR"):
		LocalPlayer.platform = "OpenVR"
	else:
		LocalPlayer.platform = "Pancake"
	if vrenabled:
		vr.initialize()
		if not vr.inVR:
			LocalPlayer.platform = "Pancake"
	LocalPlayer.get_node("HeadCam/csgheadmesh/skullcomponent").material.albedo_color = playercolour
	
# To access recorded files, do:
# > /home/julian/Android/Sdk/platform-tools/adb exec-out run-as org.dammertz.vr.godot_oculus_quest_toolkit_demo ls -alh files


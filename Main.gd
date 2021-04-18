extends Spatial

export var vrenabled = true

onready var NetworkGateway = $OQ_VisibilityToggle/OQ_UI2DCanvas.ui_control
onready var LocalPlayer = $RemotePlayers.LocalPlayer

func _ready():
	randomize()
	$OQ_ARVROrigin.transform.origin.x += rand_range(-3, 3)
	$OQ_ARVROrigin.transform.origin.z += rand_range(-1, 1)
	LocalPlayer.playercolour = Color.from_hsv(rand_range(0, 1), rand_range(0.5, 0.86), 0.75)
	print(ARVRServer.get_interfaces())
	if OS.has_feature("Server"):
		vrenabled = false
		LocalPlayer.platform = "Server"
		LocalPlayer.playercolour = Color(0.01, 0.01, 0.05)
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

		
var framerateratereducer = 5
var framecount = 0
var doppelgangertimeoffset = 10.0
var doppelgangerdelaystack = [ ]
const doppelgangerdelaystackmaxsize = 100
var cumulativetime = 0.0
func _physics_process(delta):
	cumulativetime += delta
	var tstamp = OS.get_ticks_msec()*0.001

	if $RemotePlayers.has_node("Doppelganger"):
		var fd = $RemotePlayers.LocalPlayer.avatartoframedata()
		fd[$RemotePlayers.LocalPlayer.CFI.ORIGINTRANS] *= Transform(Basis().rotated(Vector3(0,1,0), PI), Vector3(0,0,-2))
		$RemotePlayers.get_node("Doppelganger").framedatatoavatar(fd)
	return

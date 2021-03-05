extends Spatial

export var vrenabled = true
var platform = ""
var playercolour = Color(1.0, 1.0, 1.0)
var guardianpoly = PoolVector3Array([Vector3(1,0,1), Vector3(1,0,-1), Vector3(-1,0,-1), Vector3(-1,0,1)])

var ovr_init_config = null
var ovr_performance = null
var ovr_hand_tracking = null
var ovr_guardian_system = null

var framefilter = FrameInterpolation.FrameFilter.new([
			{"name":"arvrorigin", "type":"V3", "precision":0.002}, 
			{"name":"arvrbasis",  "type":"B",  "precision":0.005}, 
			{"name":"arvrcameraorigin", "type":"V3", "precision":0.002}, 
			{"name":"arvrcamerabasis",  "type":"B",  "precision":0.005}
				])

onready var NetworkGateway = $OQ_UI2DCanvas/Viewport/NetworkGateway

func _on_oq_static_grab_started(grabbed_object, controller):
	print(grabbed_object, controller)

func _ready():
	$OQ_ARVROrigin/OQ_LeftController/Feature_RigidBodyGrab.connect("oq_static_grab_started", self, "_on_oq_static_grab_started")

	randomize()
	playercolour = Color.from_hsv((randi()%10000)/10000.0, 0.5 + (randi()%2222)/6666.0, 0.75)
	print(ARVRServer.get_interfaces())
	if OS.has_feature("Server"):
		vrenabled = false
		platform = "Server"
		playercolour = Color(0.01, 0.01, 0.05)
	elif ARVRServer.find_interface("OVRMobile"):
		platform = "OVRMobile"
		vrenabled = true
	elif vrenabled and ARVRServer.find_interface("Oculus"):
		platform = "Oculus"
	elif vrenabled and ARVRServer.find_interface("OpenVR"):
		platform = "OpenVR"
	else:
		platform = "Pancake"
	if vrenabled:
		vr.initialize()
		if not vr.inVR:
			platform = "Pancake"
		elif platform == "OVRMobile":
			ovr_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
			ovr_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
			ovr_hand_tracking = load("res://addons/godot_ovrmobile/OvrHandTracking.gdns").new();
			ovr_guardian_system = load("res://addons/godot_ovrmobile/OvrGuardianSystem.gdns").new();
			guardianpoly = $OQ_ARVROrigin.ovr_guardian_system.get_boundary_geometry()
			print("guardianpoly ", guardianpoly)

func _physics_process(delta):
	var cf = framefilter.CompressFrame(OS.get_ticks_msec()*0.001, 
		[
			$OQ_ARVROrigin.transform.origin, 
			$OQ_ARVROrigin.transform.basis, 
			$OQ_ARVROrigin/OQ_ARVRCamera.transform.origin, 
			$OQ_ARVROrigin/OQ_ARVRCamera.transform.basis, 
		])
	if len(cf) > 1 and NetworkGateway.networkID > 0:
		cf[FrameInterpolation.CFINDEX.ID] = NetworkGateway.networkID
		NetworkGateway.rpc("gnextcompressedframe", cf)


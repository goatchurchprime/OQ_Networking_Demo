extends Node

const CFI_TIMESTAMP 		= -1 

var framedata0 = { }
func thinframedatatolerance(fd):
	var vd = { }
	for k in fd:
		var v = fd[k]
		var ty = typeof(v)
		if ty == TYPE_TRANSFORM:
			pass
		elif ty == TYPE_QUAT:
			0x10000

var framedividerVal = 5
var framedividerCount = framedividerVal
func _process(delta):
	if vr.vrOrigin != null:
		get_parent().arvrcontrolstoavatar()

	var tstamp = OS.get_ticks_msec()*0.001
	framedividerCount -= 1
	if framedividerCount > 0:
		return
	framedividerCount = framedividerVal

	var fd = get_parent().avatartoframedata()

	if get_parent().networkID >= 1:
		fd[CFI_TIMESTAMP] = tstamp
		get_node("PlayerFrame").rpc("networkedavatarframedata", fd)
	var doppelgangernode = get_parent().get_parent().get_node_or_null("Doppelganger")
	if doppelgangernode != null:
		fd[CFI_TIMESTAMP] = tstamp + 100
		doppelgangernode.get_node("PlayerFrame").call_deferred("networkedavatarframedata", fd)


static func QuattoV3(q):
	return Vector3(q.x, q.y, q.z)*(-1 if q.w < 0 else 1)
	
static func V3toQuat(v):
	return Quat(v.x, v.y, v.z, sqrt(max(0.0, 1.0 - v.length_squared())))




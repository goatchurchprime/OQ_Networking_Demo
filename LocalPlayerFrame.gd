extends Node

const CFI_TIMESTAMP 		= -1 
const CFI_ORIGINTRANS 		= 100
		
func _process(delta):
	if vr.vrOrigin != null:
		get_parent().arvrcontrolstoavatar()

var framedividerVal = 5
var framedividerCount = framedividerVal
func _physics_process(delta):
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

extends Node

const CFI_ORIGINTRANS_POS	= 100
const CFI_ORIGINTRANS_QUAT 	= 110
remote func networkedavatarframedata(fd):
	if get_parent().get_name() == "Doppelganger":
		fd[CFI_ORIGINTRANS_QUAT] *= Quat(Vector3(0,1,0), PI)
		fd[CFI_ORIGINTRANS_POS] += Vector3(0,0,-2)
	get_parent().framedatatoavatar(fd)

extends Node

const CFI_ORIGINTRANS 		= 100
remote func networkedavatarframedata(fd):
	if get_parent().get_name() == "Doppelganger":
		fd[CFI_ORIGINTRANS] *= Transform(Basis().rotated(Vector3(0,1,0), PI), Vector3(0,0,-2))
	get_parent().framedatatoavatar(fd)

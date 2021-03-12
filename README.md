# OQ_Networking_Demo

Networking VR players using OQ toolkit to force reuse of code

# Installation Instructions

The main dependency is on the `Oculus Quest VR Toolkit`:
   https://github.com/NeoSpark314/godot_oculus_quest_toolkit/tree/master/OQ_Toolkit

But there are also dependencies on `Godot Oculus Mobile Plugin` and `OpenVR module`

As there needed to be some edits, I have included the dependency on the godot_oculus_quest_toolkit.  
The differences can seen by running:
> diff OQ_Networking_Demo/OQ_Toolkit/ godot_oculus_quest_toolkit/OQ_Toolkit/

* *Put OQ_Toolkit/vr_autoload.gd into the Project AutoLoad as vr_autoload*

Fetch the other two assets from the assetlibrary
* `Godot Oculus Mobile Plugin` <-- **ONLY THE addons DIRECTORY**
* `OpenVR module`              <-- **ONLY THE addons DIRECTORY** (not nessary if you have no PCVR)
  
  
# Release instructions:

On the tunnelvr.goatchurch.org.uk server, use a screen instance and do:

> wget https://github.com/goatchurchprime/OQ_Networking_Demo/releases/download/v0.1.1/OQ_Networking_Demo.pck

> ./Godot_v3.2.3-stable_linux_headless.64 --main-pack OQ_Networking_Demo.pck


When running you can select server mode or leave as local network mode and it will discover 
a local server instance using UDP broadcasting.

Or connect to a gloabl server like tunnelvr.goatchurch.org.uk

Your motions will be compressed and delayed by one second.
  
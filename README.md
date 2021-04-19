# OQ_Networking_Demo

Networking between VR players code compatible with the OQ toolkit, with server discovery in Local Area Networks 

## Installation Instructions

The main dependency is on the `Oculus Quest VR Toolkit`:
   https://github.com/NeoSpark314/godot_oculus_quest_toolkit/tree/master/OQ_Toolkit

The source code of this is small, so it has been duplicated into this repository

The other dependencies you need to fetch from the AssetLib in order to run this 
are `Godot Oculus Mobile Plugin` and `OpenVR module`

Fetch these, but only install the parts that are in the `addons` directory.

## Testing the doppelganger avatar

Hit the 'G' key to toggle the Doppelganger, which is your avatar played back at a different position.
This will be useful for developing compression and interpolation features and to see what you 
look like.

## Testing locally

You can run this between two instances of Godot on the same computer (don't forget to change the 
Editor -> Settings -> Network -> Debug -> Remote port if you want to see the 
debug messages from both instances).

Then hit '1' on the first instance to set it as the Server, and '2' on the second instance 
to set it as the client "Local network".  The Server instance will then broadcast a UDP 
packet with the phrase "OQServer_here!" on 255.255.255.255 port 4546 every 2 seconds, and 
the client instance will listen for it to get its ipnumber, whereupon it will automatically 
connect using ENET and implement the stages described in 
https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

Use the right mouse button to drag the view to see the other player avatar in the area, and 
perform motions described by the VR simulator keys.

## Testing on a Quest2 or other VR appliance

Instructions are the same as above.  Make sure both are connected to the same Local (Wifi) 
network.  The Quest2 can operate either as a Server or a Client.  Hand tracking is enabled.

## Testing with a server on the internet 

Put your server url or ipnumber in the list of remoteservers.  Then log on to your server 
use a screen instance and do:

> wget https://github.com/goatchurchprime/OQ_Networking_Demo/releases/download/v0.2/OQ_Networking_Demo.pck

> ./Godot_v3.2.3-stable_linux_headless.64 --main-pack OQ_Networking_Demo.pck


# What you get in this design

The theory of networked players is as follows.  Firstly, the HMD and hand/controller positions must be mapped to a 
self-contained, possibly invisible, avatar instance.  Then the positions and pose of this avatar 
is transmitted to its peers.  The NetworkGateway module is responsible for all the setting up, player connections, initializations, 
and disconnections.

This version has no motion compression or frame interpolation.  The positions are simply sampled at 4 times a second, 
transmitted and replayed.

To fit with the modular design of the OQ_Toolkit, avatar modules (as they develop) should be self-contained 
and interchangeable.  They are not strictly humanoid.  For example, a Beep Saber avatar will have long retractable 
appendages for hands.



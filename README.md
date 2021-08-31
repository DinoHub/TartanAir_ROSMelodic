# TartanAir_ROSMelodic
Contains dockerfile for ROSMelodic and TartanAir repo dependencies.

This is meant to start compartmentalise the UE4_AirSim_ROSMelodic docker image to eventually deploy UE4 as a service in private cloud.
The intent is to explore UE4 container to serve multiple processes and limit the need to ssh into the container. UE4 pixel streaming was mentioned but need to try out. 

First step: Bring out ROSMelodic with TartanAir dependencies into a separate docker image. 
1. Need some changes to code. 
In mapping/ExpoController.py
- inject ue4 container's ip. e.g. self.cmd_client = airsim.VehicleClient(ip=args.ue4_ip)

2. create a docker network for both containers to talk. Or use the default one. 

Second step: Explore UE4 pixel streaming. 

Also explore the UE4 package thingy.

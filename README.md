# Liquid Galaxy Preliminary Task 2 for GSoC 2024

## UI

<img width="303" alt="image" src="https://github.com/ryanmckim/GSoC_2024_Pre2/assets/72713726/d19068b2-5e7a-4c78-ae4f-f16ea5da4998">

<img width="302" alt="image" src="https://github.com/ryanmckim/GSoC_2024_Pre2/assets/72713726/4779de1e-5eb2-4f3c-b73e-30ff8ea619f7">



## Description

A simple flutter application that:
1) Restarts the LG rig.
2) Moves to Vancouver, BC, Canada.
3) Moves to Vancouver, BC, Canada and starts orbiting slowly.
4) Displays an image that contains my name on the right VM (LG2).
5) Cleans the KML data on screen.
6) Has a connection manager page that allows users to connect to the LG rig with the chosen number of screens.

The application uses the dartssh package to connect to the LG rigs via ssh (with username, password, IP, port, and number of screens) to execute commands for each options listed above. KML strings were used for the machine to move around to the locations listed for the 2nd and 3rd options above.

## Compatibility

Minimum Android SDK is 30 (Android 11+) and the app is configured for tablet.

# Liquid Galaxy Preliminary Task 2 for GSoC 2024

## UI

<img width="305" alt="image" src="https://github.com/ryanmckim/GSoC_2024_Pre2/assets/72713726/109b40cc-4d4f-474f-9236-85fe2da9ff86">

## Description

A simple flutter application that:
1) Restarts the LG rig.
2) Moves to Vancouver, BC, Canada.
3) Moves to Vancouver, BC, Canada and starts orbiting slowly.
4) Displays an image that contains my name on the right VM (LG2).

The application uses the dartssh package to connect to the LG rigs via ssh (with username, password, IP, and port) to execute commands for each options listed above. KML strings were used for the machine to move around to the locations listed for the 2nd and 3rd options above.

## Compatibility

Minimum Android SDK is 30 (Android 11+) and the app is configured for tablet.